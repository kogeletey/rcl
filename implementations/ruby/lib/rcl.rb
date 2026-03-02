require_relative "rcl/parser"
require_relative "rcl/formatter"
require_relative "rcl/converters"

module RCL
  module_function

  def parse(text)
    Parser.new(text).parse
  end

  def format(ast)
    Formatter.new.format(ast)
  end

  def to_object(ast)
    Converters.to_object(ast)
  end

  def to_yaml(ast)
    Converters.to_yaml(ast)
  end

  def to_toml(ast)
    Converters.to_toml(ast)
  end

  def to_hcl(ast)
    Converters.to_hcl(ast)
  end
end
