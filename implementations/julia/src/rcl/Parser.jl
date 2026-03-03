mutable struct Parser
  lexer::Lexer
  current
end
Parser(s::String) = begin lx = Lexer(s); Parser(lx, next_token!(lx)) end
parse_error(tok, msg) = error("$msg at line $(tok.line), column $(tok.col)")

function eat!(p::Parser, typ)
  p.current.typ == typ || parse_error(p.current, "Expected $typ, got $(p.current.typ)")
  p.current = next_token!(p.lexer)
end

function peek_token(p::Parser)
  st = (pos=p.lexer.pos, line=p.lexer.line, col=p.lexer.col)
  t = next_token!(p.lexer)
  p.lexer.pos, p.lexer.line, p.lexer.col = st.pos, st.line, st.col
  t
end

function peek_token_at(p::Parser, offset::Int)
  st = (pos=p.lexer.pos, line=p.lexer.line, col=p.lexer.col)
  tok = p.current
  for _ in 1:offset; tok = next_token!(p.lexer) end
  p.lexer.pos, p.lexer.line, p.lexer.col = st.pos, st.line, st.col
  tok
end

isprefix(a::AbstractVector{<:AbstractString}, b::AbstractVector{<:AbstractString}) =
  length(a) < length(b) && all(a[i] == b[i] for i in eachindex(a))

function parse_property_key!(p::Parser)
  key = p.current.value; eat!(p, :IDENT)
  while p.current.typ == :DOT
    eat!(p, :DOT)
    p.current.typ == :IDENT || parse_error(p.current, "Expected identifier after dot")
    key *= "." * p.current.value
    eat!(p, :IDENT)
  end
  key
end

function ensure_key!(p::Parser, key::String, seen::Vector{String})
  key in seen && parse_error(p.current, "Duplicate key '$key'")
  parts = split(key, ".")
  for ex in seen
    ex_parts = split(ex, ".")
    (isprefix(parts, ex_parts) || isprefix(ex_parts, parts)) && parse_error(p.current, "Key conflict between '$key' and '$ex'")
  end
  push!(seen, key)
end

function parse_value!(p::Parser)
  t = p.current
  if t.typ == :STRING; eat!(p, :STRING); return Dict("kind"=>"string", "value"=>t.value) end
  if t.typ == :NUMBER
    eat!(p, :NUMBER)
    n = occursin('.', t.value) ? Base.parse(Float64, t.value) : Base.parse(Int64, t.value)
    return Dict("kind"=>"number", "value"=>n)
  end
  if t.typ == :IDENT
    eat!(p, :IDENT)
    t.value == "true" && return Dict("kind"=>"boolean", "value"=>true)
    t.value == "false" && return Dict("kind"=>"boolean", "value"=>false)
    parse_error(t, "Invalid bare value '$(t.value)'")
  end
  t.typ == :LBRACK && return parse_array!(p)
  t.typ == :DO && return Dict("kind"=>"block", "block"=>parse_anonymous_block!(p))
  parse_error(t, "Unexpected token: $(t.typ)")
end

function parse_array!(p::Parser)
  eat!(p, :LBRACK)
  els = Any[]
  if p.current.typ != :RBRACK
    push!(els, parse_value!(p))
    while p.current.typ == :COMMA
      peek_token(p).typ == :RBRACK && parse_error(p.current, "Trailing comma in array")
      eat!(p, :COMMA)
      push!(els, parse_value!(p))
    end
  end
  p.current.typ == :RBRACK || parse_error(p.current, "Missing ]")
  eat!(p, :RBRACK)
  Dict("kind"=>"array", "elements"=>els)
end

function parse_block!(p::Parser)
  name = p.current.value; eat!(p, :IDENT)
  arg = nothing
  if p.current.typ == :STRING; arg = p.current.value; eat!(p, :STRING) end
  eat!(p, :DO)
  props, prop_order, blocks, named = parse_block_body!(p)
  eat!(p, :END)
  Dict("kind"=>"block", "name"=>name, "argument"=>arg, "properties"=>props, "property_order"=>prop_order, "blocks"=>blocks, "named_blocks"=>named)
end

function parse_anonymous_block!(p::Parser)
  eat!(p, :DO)
  props, prop_order, blocks, named = parse_block_body!(p)
  eat!(p, :END)
  Dict("kind"=>"block", "name"=>"", "argument"=>nothing, "properties"=>props, "property_order"=>prop_order, "blocks"=>blocks, "named_blocks"=>named)
end

function parse_block_body!(p::Parser)
  props, prop_order, blocks, named, seen = Dict{String,Any}(), String[], Any[], Any[], String[]
  while p.current.typ != :END
    p.current.typ == :EOF && parse_error(p.current, "missing 'end' for block")
    p.current.typ == :IDENT || parse_error(p.current, "expected identifier, got $(p.current.typ)")
    nxt = peek_token_at(p, 1)
    if nxt.typ == :DO
      after_do = peek_token_at(p, 2)
      if after_do.typ == :LBRACK
        key = p.current.value
        eat!(p, :IDENT)
        ensure_key!(p, key, seen)
        eat!(p, :DO)
        props[key] = parse_array!(p)
        push!(prop_order, key)
        eat!(p, :END)
      else
        child = parse_block!(p)
        isnothing(child["argument"]) ? push!(blocks, child) : push!(named, child)
      end
    elseif nxt.typ == :STRING
      child = parse_block!(p)
      isnothing(child["argument"]) ? push!(blocks, child) : push!(named, child)
    elseif nxt.typ == :EQ || nxt.typ == :DOT
      key = parse_property_key!(p)
      ensure_key!(p, key, seen)
      eat!(p, :EQ)
      props[key] = parse_value!(p)
      push!(prop_order, key)
    else
      parse_error(p.current, "invalid statement after '$(p.current.value)'")
    end
  end
  props, prop_order, blocks, named
end

function parse_rcl(s::String)
  p = Parser(s)
  if p.current.typ == :DO
    eat!(p, :DO)
    root = parse_array!(p)
    p.current.typ == :EOF || parse_error(p.current, "unexpected token after root array")
    return Dict("kind"=>"document", "blocks"=>Any[], "root_value"=>root)
  end
  blocks = Any[]
  while p.current.typ != :EOF; push!(blocks, parse_block!(p)) end
  Dict("kind"=>"document", "blocks"=>blocks, "root_value"=>nothing)
end
