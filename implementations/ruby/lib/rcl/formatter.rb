module RCL
  class Formatter
    def format(ast)
      ast.fetch("blocks").map { |b| format_block(b, 0) }.join("\n\n")
    end

    private

    def format_block(block, indent)
      pad = "  " * indent
      header = if block["argument"]
                 "#{pad}#{block.fetch("name")} #{quote(block.fetch("argument"))} do"
               else
                 "#{pad}#{block.fetch("name")} do"
               end
      lines = [header]

      block.fetch("properties", {}).each do |k, v|
        lines << "#{pad}  #{k} = #{format_value(v)}"
      end

      block.fetch("blocks", {}).each_value do |child|
        lines << format_block(child, indent + 1)
      end
      block.fetch("named_blocks", []).each do |child|
        lines << format_block(child, indent + 1)
      end

      lines << "#{pad}end"
      lines.join("\n")
    end

    def format_value(node)
      case node.fetch("kind")
      when "string"
        quote(node.fetch("value"))
      when "number"
        node.fetch("value").to_s
      when "boolean"
        node.fetch("value") ? "true" : "false"
      when "array"
        "[#{node.fetch("elements").map { |e| format_value(e) }.join(", ")}]"
      else
        raise "unsupported node kind #{node.fetch("kind")}"
      end
    end

    def quote(value)
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n").gsub("\t", "\\t")
      "\"#{escaped}\""
    end
  end
end
