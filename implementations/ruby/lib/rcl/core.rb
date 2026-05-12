require_relative "parser"
require_relative "converters"

module RCL
  module Core
    module_function

    def parse(text)
      Parser.new(text).parse
    end

    def to_object(ast)
      Converters.to_object(ast)
    end
  end
end
