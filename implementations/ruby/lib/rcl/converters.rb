require "yaml"

module RCL
  module Converters
    module_function

    def to_object(doc)
      if doc["root_value"]
        return { "root" => node_to_value(doc.fetch("root_value")) }
      end
      out = {}
      doc.fetch("blocks", []).each do |b|
        if b["argument"]
          out[named_base(b["name"])] = { b["argument"] => block_to_map(b) }
        else
          out[b["name"]] = block_to_map(b)
        end
      end
      out
    end

    def to_yaml(doc)
      YAML.dump(to_object(doc)).sub(/\A---\s*\n/, "")
    end
    def to_toml(doc) = emit_toml(to_object(doc))
    def to_hcl(doc) = emit_hcl(to_object(doc), 0)

    def block_to_map(block)
      out = {}
      block.fetch("properties", {}).each { |k, v| insert_path!(out, k, node_to_value(v)) }
      children = uniq_children(block)
      children.each do |c|
        next if c["argument"]
        child = block_to_map(c)
        ex = out[c["name"]]
        out[c["name"]] = ex.is_a?(Hash) ? child.merge(ex) : child
      end
      children.each do |c|
        next unless c["argument"]
        base = named_base(c["name"])
        parent = out[base].is_a?(Hash) ? out[base] : {}
        parent[c["argument"]] = block_to_map(c)
        out[base] = parent
      end
      out
    end

    def uniq_children(block)
      seen = {}
      out = []
      block.fetch("blocks", {}).each_value do |c|
        id = c["argument"] ? "#{c["name"]}:#{c["argument"]}" : c["name"]
        next if seen[id]
        seen[id] = true
        out << c
      end
      block.fetch("named_blocks", []).each do |c|
        id = c["argument"] ? "#{c["name"]}:#{c["argument"]}" : c["name"]
        next if seen[id]
        seen[id] = true
        out << c
      end
      out
    end

    def node_to_value(node)
      case node["kind"]
      when "string" then node["value"]
      when "number" then node["value"]
      when "boolean" then node["value"]
      when "array" then node.fetch("elements", []).map { |e| node_to_value(e) }
      when "block" then block_to_map(node)
      else nil
      end
    end

    def insert_path!(target, key, value)
      parts = key.split(".")
      if parts.length == 1
        raise "duplicate key #{key}" if target.key?(key)
        target[key] = value
        return
      end
      head = parts[0]
      cur = target[head]
      raise "key conflict at #{head}" if cur && !cur.is_a?(Hash)
      branch = cur || {}
      insert_path!(branch, parts[1..].join("."), value)
      target[head] = branch
    end

    def emit_yaml(v, indent)
      pad = "  " * indent
      return pad + scalar(v) unless v.is_a?(Hash) || v.is_a?(Array)
      if v.is_a?(Array)
        return v.map { |x| x.is_a?(Hash) || x.is_a?(Array) ? "#{pad}-\n#{emit_yaml(x, indent + 1)}" : "#{pad}- #{scalar(x)}" }.join("\n")
      end
      v.keys.sort.map { |k| x = v[k]; x.is_a?(Hash) || x.is_a?(Array) ? "#{pad}#{k}:\n#{emit_yaml(x, indent + 1)}" : "#{pad}#{k}: #{scalar(x)}" }.join("\n")
    end

    def emit_toml(root)
      out = []
      walk = lambda do |obj, prefix|
        obj.keys.sort.each { |k| out << "#{k} = #{scalar(obj[k])}" unless obj[k].is_a?(Hash) }
        obj.keys.sort.each do |k|
          next unless obj[k].is_a?(Hash)
          sec = prefix ? "#{prefix}.#{k}" : k
          out << "" unless out.empty?
          out << "[#{sec}]"
          walk.call(obj[k], sec)
        end
      end
      walk.call(root, nil)
      out.join("\n")
    end

    def emit_hcl(v, indent)
      pad = "  " * indent
      return pad + scalar(v) unless v.is_a?(Hash)
      v.keys.sort.map { |k| x = v[k]; x.is_a?(Hash) ? "#{pad}#{k} {\n#{emit_hcl(x, indent + 1)}\n#{pad}}" : "#{pad}#{k} = #{scalar(x)}" }.join("\n")
    end

    def scalar(v)
      return "\"#{v.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n").gsub("\t", "\\t")}\"" if v.is_a?(String)
      return "true" if v == true
      return "false" if v == false
      return "[#{v.map { |x| scalar(x) }.join(", ")}]" if v.is_a?(Array)
      return "{}" if v.is_a?(Hash)
      v.to_s
    end

    def named_base(name)
      name.end_with?("s") ? name : "#{name}s"
    end
  end
end
