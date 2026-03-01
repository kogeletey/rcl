# RCL Parser

require "./lexer"
require "./ast"

module XrayRCL
  class Parser
    getter lexer : Lexer
    getter current_token : Token

    def initialize(@lexer)
      @current_token = @lexer.next_token
    end

    def parse : ProgramNode
      program = ProgramNode.new
      while @current_token.type != TokenType::EOF
        program.blocks << parse_block
      end
      program
    end

    private def parse_block : BlockNode
      name = @current_token.value
      eat(TokenType::Identifier)
      eat(TokenType::Do)

      properties = {} of String => ASTNode
      blocks = {} of String => BlockNode

      while @current_token.type != TokenType::End
        if @current_token.type == TokenType::Identifier
          next_token = peek_token
          if next_token.type == TokenType::Do
            block = parse_block
            blocks[block.name] = block
          elsif next_token.type == TokenType::Equal
            key = @current_token.value
            eat(TokenType::Identifier)
            eat(TokenType::Equal)
            value = parse_value
            properties[key] = value
          else
            block = parse_block
            blocks[block.name] = block
          end
        else
          break
        end
      end

      eat(TokenType::End)
      BlockNode.new(name, properties, blocks)
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
          StringNode.new(value)
        end
      when TokenType::LBracket
        parse_array
      else
        raise "Unexpected token: #{@current_token.type} at line #{@current_token.line}"
      end
    end

    private def parse_array : ArrayNode
      eat(TokenType::LBracket)
      elements = [] of ASTNode
      while @current_token.type != TokenType::RBracket
        elements << parse_value
        eat(TokenType::Comma) if @current_token.type == TokenType::Comma
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
        raise "Expected #{type}, got #{@current_token.type} at line #{@current_token.line}"
      end
    end

    private def peek_token : Token
      saved_pos, saved_line, saved_col = @lexer.pos, @lexer.line, @lexer.column
      saved_token = @current_token
      token = @lexer.next_token
      @lexer.pos, @lexer.line, @lexer.column = saved_pos, saved_line, saved_col
      @current_token = saved_token
      token
    end
  end
end
