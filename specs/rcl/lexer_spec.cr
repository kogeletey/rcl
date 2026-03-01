require "../spec_helper"

describe RCL::Lexer do
  describe "#next_token - strings" do
    it "tokenizes simple string" do
      lexer = RCL::Lexer.new("\"hello\"")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::String)
      token.value.should eq("hello")
    end

    it "tokenizes string with spaces" do
      lexer = RCL::Lexer.new("\"hello world\"")
      token = lexer.next_token
      token.value.should eq("hello world")
    end

    it "tokenizes string with escaped quotes" do
      lexer = RCL::Lexer.new("\"hello \\\"world\\\"\"")
      token = lexer.next_token
      token.value.should eq("hello \"world\"")
    end
  end

  describe "#next_token - numbers" do
    it "tokenizes small number" do
      lexer = RCL::Lexer.new("123")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Number)
      token.value.should eq("123")
    end

    it "tokenizes large number" do
      lexer = RCL::Lexer.new("12598959")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Number)
      token.value.should eq("12598959")
    end

    it "tokenizes very large number" do
      lexer = RCL::Lexer.new("987654321")
      token = lexer.next_token
      token.value.should eq("987654321")
    end
  end

  describe "#next_token - identifiers" do
    it "tokenizes simple identifier" do
      lexer = RCL::Lexer.new("server_port")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Identifier)
      token.value.should eq("server_port")
    end

    it "tokenizes identifier with numbers" do
      lexer = RCL::Lexer.new("port123")
      token = lexer.next_token
      token.value.should eq("port123")
    end
  end

  describe "#next_token - keywords" do
    it "tokenizes do keyword" do
      lexer = RCL::Lexer.new("do")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Do)
    end

    it "tokenizes end keyword" do
      lexer = RCL::Lexer.new("end")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::End)
    end

    it "tokenizes true as identifier" do
      lexer = RCL::Lexer.new("true")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Identifier)
      token.value.should eq("true")
    end

    it "tokenizes false as identifier" do
      lexer = RCL::Lexer.new("false")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Identifier)
      token.value.should eq("false")
    end
  end

  describe "#next_token - operators and delimiters" do
    it "tokenizes equal sign" do
      lexer = RCL::Lexer.new("=")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Equal)
    end

    it "tokenizes comma" do
      lexer = RCL::Lexer.new(",")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Comma)
    end

    it "tokenizes opening bracket" do
      lexer = RCL::Lexer.new("[")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::LBracket)
    end

    it "tokenizes closing bracket" do
      lexer = RCL::Lexer.new("]")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::RBracket)
    end
  end

  describe "#next_token - comments" do
    it "skips hash comments" do
      lexer = RCL::Lexer.new("# comment\nvalue")
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::Identifier)
      token.value.should eq("value")
    end

    it "skips inline hash comments" do
      lexer = RCL::Lexer.new("value # comment")
      token = lexer.next_token
      token.value.should eq("value")
    end
  end

  describe "#next_token - whitespace" do
    it "skips spaces" do
      lexer = RCL::Lexer.new("  value")
      token = lexer.next_token
      token.value.should eq("value")
    end

    it "skips newlines" do
      lexer = RCL::Lexer.new("\n\nvalue")
      token = lexer.next_token
      token.value.should eq("value")
    end

    it "tracks line numbers" do
      lexer = RCL::Lexer.new("line1\nline2")
      lexer.next_token
      token = lexer.next_token
      token.line.should eq(2)
    end
  end

  describe "#next_token - EOF" do
    it "returns EOF token at end" do
      lexer = RCL::Lexer.new("value")
      lexer.next_token
      token = lexer.next_token
      token.type.should eq(RCL::TokenType::EOF)
    end
  end
end
