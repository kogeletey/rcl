# RCL Lexer
# Tokenizes RCL configuration source code

require "./token"

module RCL
  class Lexer
    property input : String
    property pos : Int32 = 0
    property line : Int32 = 1
    property column : Int32 = 1

    def initialize(@input)
    end

    # Get next token from input
    def next_token : Token
      skip_whitespace_and_comments
      return Token.new(TokenType::EOF, "", @line, @column) if @pos >= @input.size

      char = current_char
      case char
      when '=' then advance; Token.new(TokenType::Equal, "=", @line, @column)
      when ',' then advance; Token.new(TokenType::Comma, ",", @line, @column)
      when '.' then advance; Token.new(TokenType::Dot, ".", @line, @column)
      when '[' then advance; Token.new(TokenType::LBracket, "[", @line, @column)
      when ']' then advance; Token.new(TokenType::RBracket, "]", @line, @column)
      when '"' then read_string
      when '0'..'9' then read_number
      when 't', 'f' then read_boolean
      when 'a'..'z', 'A'..'Z', '_' then read_identifier_or_keyword
      else advance; Token.new(TokenType::Identifier, char.to_s, @line, @column)
      end
    end

    private def current_char : Char
      @input[@pos]
    end

    private def advance
      @pos += 1
      @column += 1
    end

    private def peek : Char?
      @input[@pos + 1]?
    end

    # Peek at character after current position (public for parser)
    def peek_char : Char?
      @input[@pos + 1]?
    end

    # Skip whitespace and comments
    private def skip_whitespace_and_comments
      while @pos < @input.size
        char = current_char
        if char.whitespace?
          if char == '\n'
            @line += 1
            @column = 1
          else
            @column += 1
          end
          advance
        elsif char == '#'
          # Skip Ruby-style line comments
          while @pos < @input.size && current_char != '\n'
            advance
          end
        else
          break
        end
      end
    end

    # Read string value
    private def read_string : Token
      start_line, start_col = @line, @column
      advance # skip opening quote
      value = ""

      while @pos < @input.size && current_char != '"'
        if current_char == '\\' && peek == '"'
          value += '"'
          advance
          advance
        elsif current_char == '\\' && peek == 'n'
          value += '\n'
          advance
          advance
        elsif current_char == '\\' && peek == 't'
          value += '\t'
          advance
          advance
        else
          value += current_char.to_s
          advance
        end
      end

      advance # skip closing quote
      Token.new(TokenType::String, value, start_line, start_col)
    end

    # Read number value (integer or float)
    private def read_number : Token
      start_line, start_col = @line, @column
      value = ""

      # Handle negative numbers
      if current_char == '-'
        value += '-'
        advance
      end

      # Read integer part
      while @pos < @input.size && current_char.ascii_number?
        value += current_char.to_s
        advance
      end

      # Read decimal part if present
      if @pos < @input.size && current_char == '.' && peek.try(&.ascii_number?)
        value += '.'
        advance
        while @pos < @input.size && current_char.ascii_number?
          value += current_char.to_s
          advance
        end
      end

      Token.new(TokenType::Number, value, start_line, start_col)
    end

    # Read boolean value (true/false)
    private def read_boolean : Token
      start_line, start_col = @line, @column
      value = ""

      while @pos < @input.size && current_char.alphanumeric?
        value += current_char.to_s
        advance
      end

      Token.new(TokenType::Identifier, value, start_line, start_col)
    end

    # Read identifier or keyword
    private def read_identifier_or_keyword : Token
      start_line, start_col = @line, @column
      value = ""

      while @pos < @input.size && (current_char.alphanumeric? || current_char == '_')
        value += current_char.to_s
        advance
      end

      # Check for keywords
      case value
      when "do" then Token.new(TokenType::Do, value, start_line, start_col)
      when "end" then Token.new(TokenType::End, value, start_line, start_col)
      when "true", "false" then Token.new(TokenType::Identifier, value, start_line, start_col)
      else Token.new(TokenType::Identifier, value, start_line, start_col)
      end
    end
  end
end
