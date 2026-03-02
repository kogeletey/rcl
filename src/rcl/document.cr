# RCL Document
# Represents a parsed RCL configuration document
require "./ast"
require "json"
require "set"

module RCL
  class Document
    getter blocks : Array(BlockNode)
    getter root : Hash(String, ASTNode)

    def initialize(@blocks = [] of BlockNode)
      @root = {} of String => ASTNode

      # Flatten single root block if exists
      if @blocks.size == 1
        block = @blocks.first
        block.properties.each { |k, v| @root[k] = v }
        block.blocks.each { |k, v| @root[k] = v }
      else
        # Multiple blocks - index them by name
        @blocks.each do |block|
          @root[block.name] = block
        end
      end
    end

    # Get value by key (from root)
    def []?(key : String) : ASTNode?
      @root[key]?
    end

    # Get value by path (e.g., "akash.deployment_name")
    def get(path : String) : ASTNode?
      parts = path.split('.')
      current : ASTNode? = @root[parts[0]]?

      if rest = parts[1..-1]?
        rest.each do |part|
          break unless current.is_a?(BlockNode)
          current = current.as(BlockNode)[part]?
        end
      end

      current
    end

    # Get string value
    def get_string(path : String, default : String? = nil) : String?
      node = get(path)
      node.is_a?(StringNode) ? node.as(StringNode).value : default
    end

    # Get integer value
    def get_int(path : String, default : Int32? = nil) : Int32?
      node = get(path)
      if node.is_a?(NumberNode)
        value = node.as(NumberNode).value
        value.is_a?(Int32) || value.is_a?(Int64) ? value.to_i : default
      else
        default
      end
    end

    # Get float value
    def get_float(path : String, default : Float64? = nil) : Float64?
      node = get(path)
      node.is_a?(NumberNode) ? node.as(NumberNode).value.to_f : default
    end

    # Get boolean value
    def get_bool(path : String, default : Bool? = nil) : Bool?
      node = get(path)
      node.is_a?(BooleanNode) ? node.as(BooleanNode).value : default
    end

    # Get array value
    def get_array(path : String) : ArrayNode?
      node = get(path)
      node.is_a?(ArrayNode) ? node.as(ArrayNode) : nil
    end

    # Get block by name
    def block(name : String) : BlockNode?
      @root[name]?.as(BlockNode?)
    end

    # Check if key exists
    def has_key?(path : String) : Bool
      get(path).nil? == false
    end

    # Convert to Hash
    def to_h : Hash(String, RCL::Value)
      result = {} of String => RCL::Value
      @blocks.each do |block|
        result[block.name] = block_to_h(block)
      end

      # If single root block, return its contents
      if @blocks.size == 1
        return block_to_h(@blocks.first)
      end

      result
    end

    # Convert to a stable AST hash contract
    def to_ast_h : Hash(String, RCL::Value)
      {
        "kind"   => "document",
        "blocks" => @blocks.map(&.to_ast_h),
      }
    end

    def to_json(json : JSON::Builder) : Nil
      to_ast_h.to_json(json)
    end

    private def block_to_h(block : BlockNode) : Hash(String, RCL::Value)
      result = {} of String => RCL::Value

      # Add properties
      block.properties.each do |key, node|
        result[key] = node_to_h(node)
      end

      children = unique_child_blocks(block)

      plain_children = children.select { |child| child.argument.nil? }
      named_children = children.select { |child| !child.argument.nil? }

      plain_children.each do |child|
        child_h = block_to_h(child)
        existing = result[child.name]?
        if existing.is_a?(Hash(String, RCL::Value))
          result[child.name] = child_h.merge(existing) { |_k, left, right| right }
        else result[child.name] = child_h
        end
      end

      named_children.each do |child|
        base = child.name
        arg = child.argument.not_nil!
        branch = result[base]?
        branch_h = branch.is_a?(Hash(String, RCL::Value)) ? branch : ({} of String => RCL::Value)
        branch_h[arg] = block_to_h(child)
        result[base] = branch_h
      end

      result
    end

    private def node_to_h(node : ASTNode) : RCL::Value
      case node
      when StringNode
        node.value
      when NumberNode
        node.value
      when BooleanNode
        node.value
      when ArrayNode
        node.elements.map { |e| node_to_h(e) }
      when BlockNode
        block_to_h(node)
      else
        ""
      end
    end

    # Get all block names
    def block_names : Array(String)
      @blocks.map(&.name)
    end

    # Get all root keys
    def keys : Array(String)
      @root.keys
    end

    private def unique_child_blocks(block : BlockNode) : Array(BlockNode)
      seen = Set(UInt64).new
      out = [] of BlockNode
      block.blocks.each_value do |child|
        oid = child.object_id
        next if seen.includes?(oid)
        seen << oid
        out << child
      end
      block.named_blocks.each do |child|
        oid = child.object_id
        next if seen.includes?(oid)
        seen << oid
        out << child
      end
      out
    end
  end
end
