# RCL - Ray Configuration Language
# A TOML-like configuration language parser
#
# Copyright (c) 2024 Your Name
# Licensed under MIT License
#
# Syntax:
#   # Comments (Ruby-style)
#   key = "value"
#   number = 12345
#   enabled = true
#   array = [1, 2, 3]
#   
#   block do
#     nested = "value"
#   end
#
# Usage:
#   require "rcl"
#   
#   doc = RCL.parse_file("config.rcl")
#   doc.get_string("block/nested")
#   
#   # Register custom block handlers
#   RCL::Blocks.register("server") do |block|
#     {:ok, {address: block["address"]}.named_tuple}
#   end

require_relative "./rcl/version"
require_relative "./rcl/token"
require_relative "./rcl/ast"
require_relative "./rcl/lexer"
require_relative "./rcl/parser"
require_relative "./rcl/document"
require_relative "./rcl/blocks"

module RCL
  # Parse RCL file and return Document
  def self.parse_file(path : String) : Document
    content = File.read(path)
    parse_string(content)
  end

  # Parse RCL string and return Document
  def self.parse_string(content : String) : Document
    lexer = RCL::Lexer.new(content)
    parser = RCL::Parser.new(lexer)
    parser.parse
  end

  # Parse and convert to Hash
  def self.parse_file_to_h(path : String) : Hash(String, RCL::Value)
    parse_file(path).to_h
  end

  # Parse string and convert to Hash
  def self.parse_string_to_h(content : String) : Hash(String, RCL::Value)
    parse_string(content).to_h
  end
end
