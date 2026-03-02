require "set"
module RCL
  class Parser
    def initialize(text) = (@text = text; @i = 0)
    def parse
      { "kind" => "document", "blocks" => parse_blocks }
    end
    private
    def parse_blocks(stop = nil)
      out = []
      loop do
        skip_space
        break if eof?
        if stop && peek_identifier == stop
          read_identifier
          break
        end
        out << parse_block
      end
      out
    end

    def parse_block
      name = read_identifier
      arg = parse_optional_string
      expect_identifier("do")
      parse_block_body(name, arg)
    end

    def parse_block_body(name, arg)
      props, blocks, named, seen = {}, {}, [], Set.new
      loop do
        skip_space
        raise "missing end" if eof?
        break if peek_identifier == "end"
        key = read_identifier
        skip_space
        if current == '"' || peek_identifier == "do"
          child_arg = parse_optional_string
          expect_identifier("do")
          child = parse_block_body(key, child_arg)
          child_arg ? named << child : blocks[key] = child
        else
          key = read_dotted_key(key)
          ensure_key_valid!(key, seen)
          expect("=")
          props[key] = parse_value
        end
      end
      expect_identifier("end")
      h = { "kind" => "block", "name" => name, "properties" => props, "blocks" => blocks }
      h["argument"] = arg if arg
      h["named_blocks"] = named unless named.empty?
      h
    end

    def parse_value
      skip_space
      return { "kind" => "string", "value" => read_string } if current == '"'
      return parse_array if current == "["
      return parse_number if number_start?
      id = peek_identifier
      if id == "true" || id == "false"
        read_identifier
        return { "kind" => "boolean", "value" => id == "true" }
      end
      raise "invalid bare value"
    end

    def parse_number
      tok = read_number_token
      { "kind" => "number", "value" => tok.include?(".") ? tok.to_f : tok.to_i }
    end

    def parse_array
      expect("[")
      elems = []
      loop do
        skip_space
        break if current == "]"
        elems << parse_value
        skip_space
        break if current == "]"
        expect(",")
        skip_space
        raise "trailing comma in array" if current == "]"
      end
      expect("]")
      { "kind" => "array", "elements" => elems }
    end

    def parse_optional_string
      skip_space
      current == '"' ? read_string : nil
    end

    def read_dotted_key(key)
      loop do
        skip_space
        break unless current == "."
        advance
        key += ".#{read_identifier}"
      end
      key
    end

    def ensure_key_valid!(key, seen)
      raise "duplicate key #{key}" if seen.include?(key)
      parts = key.split(".")
      seen.each do |existing|
        ex = existing.split(".")
        raise "key conflict #{key} vs #{existing}" if prefix?(parts, ex) || prefix?(ex, parts)
      end
      seen << key
    end

    def prefix?(left, right)
      return false if left.length >= right.length
      left.each_with_index { |p, i| return false if p != right[i] }
      true
    end

    def read_string
      expect('"')
      out = +""
      until eof? || current == '"'
        if current == "\\"
          advance
          raise "unterminated escape" if eof?
          esc = { '"' => '"', "\\" => "\\", "n" => "\n", "t" => "\t" }[current]
          raise "invalid escape" unless esc
          out << esc
        else
          out << current
        end
        advance
      end
      raise "unterminated string" if eof?
      expect('"')
      out
    end

    def read_identifier
      skip_space
      raise "expected identifier" unless current&.match?(/[A-Za-z_]/)
      out = +""
      while !eof? && current.match?(/[A-Za-z0-9_]/)
        out << current
        advance
      end
      out
    end

    def read_number_token
      skip_space
      out = +""
      if current == "-"
        out << "-"
        advance
      end
      raise "invalid number" unless current&.match?(/[0-9]/)
      out << current && advance while !eof? && current.match?(/[0-9]/)
      if current == "." && @text[@i + 1]&.match?(/[0-9]/)
        out << "."
        advance
        out << current && advance while !eof? && current.match?(/[0-9]/)
      end
      out
    end

    def number_start?
      current&.match?(/[0-9]/) || (current == "-" && @text[@i + 1]&.match?(/[0-9]/))
    end

    def peek_identifier
      j = @i
      j += 1 while j < @text.length && @text[j].match?(/\s/)
      return "" unless @text[j]&.match?(/[A-Za-z_]/)
      out = +""
      out << @text[j] && j += 1 while j < @text.length && @text[j].match?(/[A-Za-z0-9_]/)
      out
    end

    def skip_space
      while !eof?
        if current.match?(/\s/) then advance
        elsif current == "#" then advance until eof? || current == "\n"
        else break
        end
      end
    end

    def expect(c) = (skip_space; raise("expected #{c}") unless current == c; advance)
    def expect_identifier(w) = (g = read_identifier; raise("expected #{w}, got #{g}") unless g == w)
    def current = @text[@i]
    def advance = (@i += 1)
    def eof? = (@i >= @text.length)
  end
end
