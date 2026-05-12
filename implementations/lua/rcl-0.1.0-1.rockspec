package = "rcl"
version = "0.1.0-1"
source = {
  url = "git+https://github.com/kogeletey/rcl.git",
  tag = "v0.1.0"
}
description = {
  summary = "RCL parser and formatter for Lua",
  homepage = "https://github.com/kogeletey/rcl",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["rcl"] = "rcl.lua",
    ["rcl.core"] = "rcl/core.lua",
    ["rcl.extended"] = "rcl/extended.lua",
    ["rcl.lexer"] = "rcl/lexer.lua",
    ["rcl.parser"] = "rcl/parser.lua",
    ["rcl.formatter"] = "rcl/formatter.lua",
    ["rcl.converters"] = "rcl/converters.lua"
  }
}
