local Lexer = {}
Lexer.__index = Lexer

local function err(msg, line, col)
  error(string.format("%s at line %d, column %d", msg, line, col))
end

function Lexer.new(input)
  return setmetatable({ input = input, pos = 1, line = 1, col = 1 }, Lexer)
end

function Lexer:snapshot()
  return { pos = self.pos, line = self.line, col = self.col }
end

function Lexer:restore(st)
  self.pos, self.line, self.col = st.pos, st.line, st.col
end

function Lexer:peek_char(off)
  return self.input:sub(self.pos + (off or 0), self.pos + (off or 0))
end

function Lexer:advance()
  local ch = self:peek_char(0)
  if ch == "\n" then self.line, self.col = self.line + 1, 1 else self.col = self.col + 1 end
  self.pos = self.pos + 1
end

function Lexer:skip_ws_comments()
  while self.pos <= #self.input do
    local ch = self:peek_char(0)
    if ch:match("%s") then self:advance()
    elseif ch == "#" then while self.pos <= #self.input and self:peek_char(0) ~= "\n" do self:advance() end
    else break end
  end
end

function Lexer:read_string(sl, sc)
  self:advance()
  local out = {}
  while self.pos <= #self.input and self:peek_char(0) ~= '"' do
    local ch = self:peek_char(0)
    if ch == "\\" then
      self:advance()
      if self.pos > #self.input then err("Unterminated escape", sl, sc) end
      local esc = self:peek_char(0)
      if esc == '"' then out[#out + 1] = '"'
      elseif esc == "n" then out[#out + 1] = "\n"
      elseif esc == "t" then out[#out + 1] = "\t"
      elseif esc == "\\" then out[#out + 1] = "\\"
      else err("Invalid escape sequence", self.line, self.col) end
      self:advance()
    else
      out[#out + 1] = ch
      self:advance()
    end
  end
  if self.pos > #self.input then err("Unterminated string", sl, sc) end
  self:advance()
  return { type = "STRING", value = table.concat(out), line = sl, col = sc }
end

function Lexer:read_number(sl, sc)
  local out = {}
  if self:peek_char(0) == "-" then out[#out + 1], self.pos, self.col = "-", self.pos + 1, self.col + 1 end
  while self.pos <= #self.input and self:peek_char(0):match("%d") do out[#out + 1] = self:peek_char(0); self:advance() end
  if self.pos <= #self.input and self:peek_char(0) == "." and self:peek_char(1):match("%d") then
    out[#out + 1] = "."; self:advance()
    while self.pos <= #self.input and self:peek_char(0):match("%d") do out[#out + 1] = self:peek_char(0); self:advance() end
  end
  return { type = "NUMBER", value = table.concat(out), line = sl, col = sc }
end

function Lexer:read_ident(sl, sc)
  local out = {}
  while self.pos <= #self.input and self:peek_char(0):match("[%w_]") do out[#out + 1] = self:peek_char(0); self:advance() end
  local v = table.concat(out)
  local t = (v == "do" and "DO") or (v == "end" and "END") or "IDENT"
  return { type = t, value = v, line = sl, col = sc }
end

function Lexer:next_token()
  self:skip_ws_comments()
  if self.pos > #self.input then return { type = "EOF", value = "", line = self.line, col = self.col } end
  local ch, sl, sc = self:peek_char(0), self.line, self.col
  local single = { ["="] = "EQ", [","] = "COMMA", ["."] = "DOT", ["["] = "LBRACK", ["]"] = "RBRACK" }
  local st = single[ch]
  if st then self:advance(); return { type = st, value = ch, line = sl, col = sc } end
  if ch == '"' then return self:read_string(sl, sc) end
  if ch == "'" then err("single-quoted string usage", sl, sc) end
  if ch == "/" and self:peek_char(1) == "/" then err("unexpected character '/'", sl, sc) end
  if ch:match("%d") or (ch == "-" and self:peek_char(1):match("%d")) then return self:read_number(sl, sc) end
  if ch:match("[%a_]") then return self:read_ident(sl, sc) end
  err("unexpected character '" .. ch .. "'", sl, sc)
end

return Lexer
