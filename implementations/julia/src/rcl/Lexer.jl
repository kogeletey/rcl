mutable struct Lexer
  input::String
  pos::Int
  line::Int
  col::Int
end
Lexer(s::String) = Lexer(s, firstindex(s), 1, 1)
peek(lx::Lexer, off::Int=0) = begin i = lx.pos + off; i > lastindex(lx.input) ? '\0' : lx.input[i] end

function advance!(lx::Lexer)
  ch = peek(lx)
  if ch == '\n'; lx.line += 1; lx.col = 1 else lx.col += 1 end
  lx.pos += 1
end

lex_error(msg, line, col) = error("$msg at line $line, column $col")

function skip_ws_comments!(lx::Lexer)
  while lx.pos <= lastindex(lx.input)
    ch = peek(lx)
    if isspace(ch)
      advance!(lx)
    elseif ch == '#'
      while lx.pos <= lastindex(lx.input) && peek(lx) != '\n'; advance!(lx) end
    else
      break
    end
  end
end

function read_string!(lx::Lexer, line::Int, col::Int)
  advance!(lx)
  out = IOBuffer()
  while lx.pos <= lastindex(lx.input) && peek(lx) != '"'
    ch = peek(lx)
    if ch == '\\'
      advance!(lx)
      lx.pos > lastindex(lx.input) && lex_error("Unterminated escape", line, col)
      esc = peek(lx)
      esc == '"' && write(out, '"')
      esc == 'n' && write(out, '\n')
      esc == 't' && write(out, '\t')
      esc == '\\' && write(out, '\\')
      !(esc in ('"', 'n', 't', '\\')) && lex_error("Invalid escape sequence", lx.line, lx.col)
      advance!(lx)
    else
      write(out, ch)
      advance!(lx)
    end
  end
  lx.pos > lastindex(lx.input) && lex_error("Unterminated string", line, col)
  advance!(lx)
  (typ=:STRING, value=String(take!(out)), line=line, col=col)
end

function read_number!(lx::Lexer, line::Int, col::Int)
  out = IOBuffer()
  if peek(lx) == '-'; write(out, '-'); advance!(lx) end
  while isdigit(peek(lx)); write(out, peek(lx)); advance!(lx) end
  if peek(lx) == '.' && isdigit(peek(lx, 1))
    write(out, '.'); advance!(lx)
    while isdigit(peek(lx)); write(out, peek(lx)); advance!(lx) end
  end
  (typ=:NUMBER, value=String(take!(out)), line=line, col=col)
end

function read_ident!(lx::Lexer, line::Int, col::Int)
  out = IOBuffer()
  while isletter(peek(lx)) || isdigit(peek(lx)) || peek(lx) == '_'
    write(out, peek(lx)); advance!(lx)
  end
  v = String(take!(out))
  t = v == "do" ? :DO : v == "end" ? :END : :IDENT
  (typ=t, value=v, line=line, col=col)
end

function next_token!(lx::Lexer)
  skip_ws_comments!(lx)
  lx.pos > lastindex(lx.input) && return (typ=:EOF, value="", line=lx.line, col=lx.col)
  ch, line, col = peek(lx), lx.line, lx.col
  ch == '=' && (advance!(lx); return (typ=:EQ, value="=", line=line, col=col))
  ch == ',' && (advance!(lx); return (typ=:COMMA, value=",", line=line, col=col))
  ch == '.' && (advance!(lx); return (typ=:DOT, value=".", line=line, col=col))
  ch == '[' && (advance!(lx); return (typ=:LBRACK, value="[", line=line, col=col))
  ch == ']' && (advance!(lx); return (typ=:RBRACK, value="]", line=line, col=col))
  ch == '"' && return read_string!(lx, line, col)
  ch == '\'' && lex_error("single-quoted string usage", line, col)
  ch == '/' && peek(lx, 1) == '/' && lex_error("unexpected character '/'", line, col)
  (isdigit(ch) || (ch == '-' && isdigit(peek(lx, 1)))) && return read_number!(lx, line, col)
  (isletter(ch) || ch == '_') && return read_ident!(lx, line, col)
  lex_error("unexpected character '$ch'", line, col)
end
