local info = debug.getinfo(1, "S").source
local base = info:sub(2):match("^(.*)[/\\]") or "."
local Lexer = dofile(base .. "/lexer.lua")

local Parser = {}
Parser.__index = Parser

local function err(tok, msg)
  error(string.format("%s at line %d, column %d", msg, tok.line, tok.col))
end

local function is_prefix(a, b)
  if #a >= #b then return false end
  for i = 1, #a do if a[i] ~= b[i] then return false end end
  return true
end

function Parser.new(input)
  local lx = Lexer.new(input)
  return setmetatable({ lexer = lx, current = lx:next_token() }, Parser)
end

function Parser:eat(t)
  if self.current.type ~= t then err(self.current, "Expected " .. t .. ", got " .. self.current.type) end
  self.current = self.lexer:next_token()
end

function Parser:peek()
  local st = self.lexer:snapshot()
  local tok = self.lexer:next_token()
  self.lexer:restore(st)
  return tok
end

function Parser:peek_at(offset)
  local st = self.lexer:snapshot()
  local tok = self.current
  for _ = 1, offset do tok = self.lexer:next_token() end
  self.lexer:restore(st)
  return tok
end

function Parser:parse_property_key()
  local key = self.current.value
  self:eat("IDENT")
  while self.current.type == "DOT" do
    self:eat("DOT")
    if self.current.type ~= "IDENT" then err(self.current, "Expected identifier after dot") end
    key = key .. "." .. self.current.value
    self:eat("IDENT")
  end
  return key
end

function Parser:ensure_key(key, seen)
  if seen[key] then err(self.current, "Duplicate key '" .. key .. "'") end
  local parts = {}
  for p in key:gmatch("[^.]+") do parts[#parts + 1] = p end
  for k, _ in pairs(seen) do
    local ex = {}
    for p in k:gmatch("[^.]+") do ex[#ex + 1] = p end
    if is_prefix(parts, ex) or is_prefix(ex, parts) then err(self.current, "Key conflict between '" .. key .. "' and '" .. k .. "'") end
  end
  seen[key] = true
end

function Parser:parse_value()
  local t = self.current
  if t.type == "STRING" then self:eat("STRING"); return { kind = "string", value = t.value } end
  if t.type == "NUMBER" then self:eat("NUMBER"); return { kind = "number", value = tonumber(t.value) } end
  if t.type == "IDENT" then
    self:eat("IDENT")
    if t.value == "true" or t.value == "false" then return { kind = "boolean", value = t.value == "true" } end
    err(t, "Invalid bare value '" .. t.value .. "'")
  end
  if t.type == "LBRACK" then return self:parse_array() end
  if t.type == "DO" then return { kind = "block", block = self:parse_anonymous_block() } end
  err(t, "Unexpected token: " .. t.type)
end

function Parser:parse_array()
  self:eat("LBRACK")
  local elements = {}
  if self.current.type ~= "RBRACK" then
    elements[#elements + 1] = self:parse_value()
    while self.current.type == "COMMA" do
      if self:peek().type == "RBRACK" then err(self.current, "Trailing comma in array") end
      self:eat("COMMA")
      elements[#elements + 1] = self:parse_value()
    end
  end
  if self.current.type ~= "RBRACK" then err(self.current, "Missing ]") end
  self:eat("RBRACK")
  return { kind = "array", elements = elements }
end

function Parser:parse_block_body()
  local props, prop_order, blocks, named, seen = {}, {}, {}, {}, {}
  while self.current.type ~= "END" do
    if self.current.type == "EOF" then err(self.current, "missing 'end' for block") end
    if self.current.type ~= "IDENT" then err(self.current, "expected identifier, got " .. self.current.type) end
    local nxt = self:peek_at(1)
    if nxt.type == "DO" then
      local after_do = self:peek_at(2)
      if after_do.type == "LBRACK" then
        local key = self.current.value
        self:eat("IDENT")
        self:ensure_key(key, seen)
        self:eat("DO")
        props[key] = self:parse_array()
        prop_order[#prop_order + 1] = key
        self:eat("END")
      else
        local child = self:parse_block()
        if child.argument then named[#named + 1] = child else blocks[#blocks + 1] = child end
      end
    elseif nxt.type == "STRING" then
      local child = self:parse_block()
      if child.argument then named[#named + 1] = child else blocks[#blocks + 1] = child end
    elseif nxt.type == "EQ" or nxt.type == "DOT" then
      local key = self:parse_property_key()
      self:ensure_key(key, seen)
      self:eat("EQ")
      props[key] = self:parse_value()
      prop_order[#prop_order + 1] = key
    else
      err(self.current, "invalid statement after '" .. self.current.value .. "'")
    end
  end
  return props, prop_order, blocks, named
end

function Parser:parse_block()
  local name = self.current.value
  self:eat("IDENT")
  local argument = nil
  if self.current.type == "STRING" then argument = self.current.value; self:eat("STRING") end
  self:eat("DO")
  local props, prop_order, blocks, named = self:parse_block_body()
  self:eat("END")
  return { kind = "block", name = name, argument = argument, properties = props, property_order = prop_order, blocks = blocks, named_blocks = named }
end

function Parser:parse_anonymous_block()
  self:eat("DO")
  local props, prop_order, blocks, named = self:parse_block_body()
  self:eat("END")
  return { kind = "block", name = "", argument = nil, properties = props, property_order = prop_order, blocks = blocks, named_blocks = named }
end

function Parser:parse()
  if self.current.type == "DO" then
    self:eat("DO")
    local root = self:parse_array()
    if self.current.type ~= "EOF" then err(self.current, "unexpected token after root array") end
    return { kind = "document", blocks = {}, root_value = root }
  end
  local out = { kind = "document", blocks = {}, root_value = nil }
  while self.current.type ~= "EOF" do out.blocks[#out.blocks + 1] = self:parse_block() end
  return out
end

return function(input)
  return Parser.new(input):parse()
end
