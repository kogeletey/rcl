require "./lexer"
require "./ast"
require "set"

module RCL
  class Parser
    getter lexer : Lexer
    getter current_token : Token

    def initialize(@lexer)
      @current_token = @lexer.next_token
    end

    def self.parse(content : String) : Document
      lexer = RCL::Lexer.new(content)
      new(lexer).parse
    end

    def parse : Document
      if @current_token.type == TokenType::Do
        eat(TokenType::Do)
        root_array = parse_array
        raise "Unexpected token after root array at line #{@current_token.line}, column #{@current_token.column}" unless @current_token.type == TokenType::EOF
        return Document.new([] of BlockNode, root_value: root_array)
      end

      blocks = [] of BlockNode

      while @current_token.type != TokenType::EOF
        blocks << parse_block
      end

      Document.new(blocks)
    end

    private def parse_block : BlockNode
      name = @current_token.value
      eat(TokenType::Identifier)

      argument : String? = nil
      if @current_token.type == TokenType::String
        argument = @current_token.value
        eat(TokenType::String)
      end

      eat(TokenType::Do)

      properties, blocks, named_blocks = parse_block_body

      eat(TokenType::End)
      BlockNode.new(name, argument, properties, blocks, named_blocks)
    end

    private def parse_anonymous_block : BlockNode
      eat(TokenType::Do)
      properties, blocks, named_blocks = parse_block_body
      eat(TokenType::End)
      BlockNode.new("", nil, properties, blocks, named_blocks)
    end

    private def parse_block_body
      properties = {} of String => ASTNode
      blocks = {} of String => BlockNode
      named_blocks = [] of BlockNode
      seen_keys = Set(String).new

      while @current_token.type != TokenType::End
        if @current_token.type == TokenType::EOF
          raise "missing 'end' for block at line #{@current_token.line}, column #{@current_token.column}"
        end
        raise "Expected identifier at line #{@current_token.line}, column #{@current_token.column}" unless @current_token.type == TokenType::Identifier

        next_token = peek_token
        if next_token.type == TokenType::Do
          after_do = peek_token(2)
          if after_do.type == TokenType::LBracket
            key = @current_token.value
            eat(TokenType::Identifier)
            ensure_property_key_valid!(key, seen_keys)
            eat(TokenType::Do)
            properties[key] = parse_array
            eat(TokenType::End)
          else
            child = parse_block
            if child.argument
              named_blocks << child
            else
              blocks[child.name] = child
            end
          end
        elsif next_token.type == TokenType::String
          child = parse_block
          if child.argument
            named_blocks << child
          else
            blocks[child.name] = child
          end
        elsif next_token.type == TokenType::Equal || next_token.type == TokenType::Dot
          key = parse_property_key
          ensure_property_key_valid!(key, seen_keys)
          eat(TokenType::Equal)
          properties[key] = parse_value
        else
          raise "invalid statement after '#{@current_token.value}' at line #{@current_token.line}, column #{@current_token.column}"
        end
      end

      {properties, blocks, named_blocks}
    end

    private def parse_property_key : String
      key = @current_token.value
      eat(TokenType::Identifier)

      while @current_token.type == TokenType::Dot
        eat(TokenType::Dot)
        raise "Expected identifier after dot at line #{@current_token.line}, column #{@current_token.column}" unless @current_token.type == TokenType::Identifier
        key += "." + @current_token.value
        eat(TokenType::Identifier)
      end

      key
    end

    private def parse_value : ASTNode
      case @current_token.type
      when TokenType::String
        value = @current_token.value
        eat(TokenType::String)
        StringNode.new(value)
      when TokenType::Number
        value = parse_number(@current_token.value)
        eat(TokenType::Number)
        NumberNode.new(value)
      when TokenType::Identifier
        value = @current_token.value
        eat(TokenType::Identifier)
        if value == "true"
          BooleanNode.new(true)
        elsif value == "false"
          BooleanNode.new(false)
        else
          raise "Invalid bare value '#{value}' at line #{@current_token.line}, column #{@current_token.column}"
        end
      when TokenType::LBracket
        parse_array
      when TokenType::Do
        parse_anonymous_block
      else
        raise "Unexpected token: #{@current_token.type} at line #{@current_token.line}"
      end
    end

    private def parse_array : ArrayNode
      eat(TokenType::LBracket)
      elements = [] of ASTNode

      while @current_token.type != TokenType::RBracket
        elements << parse_value
        if @current_token.type == TokenType::Comma
          eat(TokenType::Comma)
          if @current_token.type == TokenType::RBracket
            raise "Trailing comma in array at line #{@current_token.line}, column #{@current_token.column}"
          end
        end
      end

      eat(TokenType::RBracket)
      ArrayNode.new(elements)
    end

    private def parse_number(value : String) : Int32 | Int64 | Float64
      if value.includes?('.')
        value.to_f
      elsif value.to_i64 > Int32::MAX || value.to_i64 < Int32::MIN
        value.to_i64
      else
        value.to_i
      end
    end

    private def eat(type : TokenType)
      if @current_token.type == type
        @current_token = @lexer.next_token
      else
        raise "Expected #{type}, got #{@current_token.type} at line #{@current_token.line}, column #{@current_token.column}"
      end
    end

    private def peek_token(offset : Int32 = 1) : Token
      saved_pos, saved_line, saved_col = @lexer.pos, @lexer.line, @lexer.column
      saved_token = @current_token

      token = @current_token
      offset.times do
        token = @lexer.next_token
      end

      @lexer.pos, @lexer.line, @lexer.column = saved_pos, saved_line, saved_col
      @current_token = saved_token

      token
    end

    private def ensure_property_key_valid!(key : String, seen : Set(String))
      if seen.includes?(key)
        raise "Duplicate key '#{key}' at line #{@current_token.line}, column #{@current_token.column}"
      end
      key_parts = key.split('.')
      seen.each do |existing|
        parts = existing.split('.')
        if prefix?(key_parts, parts) || prefix?(parts, key_parts)
          raise "Key conflict between '#{key}' and '#{existing}' at line #{@current_token.line}, column #{@current_token.column}"
        end
      end
      seen << key
    end

    private def prefix?(left : Array(String), right : Array(String)) : Bool
      return false if left.size >= right.size
      left.each_with_index do |part, idx|
        return false if right[idx] != part
      end
      true
    end
  end
end
