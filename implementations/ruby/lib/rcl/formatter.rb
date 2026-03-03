module RCL
  class Formatter
    def format(ast)
      if ast["root_value"]&.fetch("kind", nil) == "array"
        return "do #{format_value(ast.fetch("root_value"))}"
      end
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
        if v.fetch("kind") == "array"
          lines << "#{pad}  #{k} do #{format_value(v)} end"
        else
          lines << "#{pad}  #{k} = #{format_value(v)}"
        end
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
      when "block"
        format_anonymous_block(node)
      else
        raise "unsupported node kind #{node.fetch("kind")}"
      end
    end

    def format_anonymous_block(block)
      parts = []
      block.fetch("properties", {}).each { |k, v| parts << "#{k} = #{format_value(v)}" }
      block.fetch("blocks", {}).each_value { |child| parts << format_inline_block(child) }
      block.fetch("named_blocks", []).each { |child| parts << format_inline_block(child) }
      parts.empty? ? "do end" : "do #{parts.join(" ")} end"
    end

    def format_inline_block(block)
      head = if block["argument"]
               "#{block.fetch("name")} #{quote(block.fetch("argument"))} do"
             else
               "#{block.fetch("name")} do"
             end
      parts = []
      block.fetch("properties", {}).each { |k, v| parts << "#{k} = #{format_value(v)}" }
      block.fetch("blocks", {}).each_value { |child| parts << format_inline_block(child) }
      block.fetch("named_blocks", []).each { |child| parts << format_inline_block(child) }
      parts.empty? ? "#{head} end" : "#{head} #{parts.join(" ")} end"
    end

    def quote(value)
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n").gsub("\t", "\\t")
      "\"#{escaped}\""
    end
  end
end
