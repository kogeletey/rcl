# RCL AST Nodes
# Abstract Syntax Tree for RCL configuration

module RCL
  # Base AST node
  abstract class ASTNode
  end

  # String value node
  class StringNode < ASTNode
    getter value : String
    def initialize(@value); end
  end

  # Number value node (Int32, Int64, or Float64)
  class NumberNode < ASTNode
    getter value : Int32 | Int64 | Float64
    def initialize(@value); end
  end

  # Boolean value node
  class BooleanNode < ASTNode
    getter value : Bool
    def initialize(@value); end
  end

  # Array of values
  class ArrayNode < ASTNode
    getter elements : Array(ASTNode)
    def initialize(@elements); end
  end

  # Block/section with nested properties and blocks
  class BlockNode < ASTNode
    getter name : String
    getter argument : String?
    getter properties : Hash(String, ASTNode)
    getter blocks : Hash(String, BlockNode)
    getter named_blocks : Array(BlockNode)

    def initialize(
      @name,
      @argument : String? = nil,
      @properties = {} of String => ASTNode,
      @blocks = {} of String => BlockNode,
      @named_blocks = [] of BlockNode
    )
    end

    # Get property or block by key
    def []?(key : String) : ASTNode?
      @properties[key]? || @blocks[key]?
    end

    # Set property
    def []=(key : String, value : ASTNode)
      @properties[key] = value
    end

    # Add a named block (block with argument)
    def add_named_block(block : BlockNode)
      @named_blocks << block
      # Also store in blocks hash with key "name:argument" for backward compatibility
      if block.argument
        @blocks["#{block.name}:#{block.argument}"] = block
      else
        @blocks[block.name] = block
      end
    end

    # Check if has key
    def has_key?(key : String) : Bool
      @properties.has_key?(key) || @blocks.has_key?(key)
    end

    # Get all keys
    def keys : Array(String)
      @properties.keys | @blocks.keys
    end
  end

  # Type alias for RCL values
  alias Value = String | Int32 | Int64 | Float64 | Bool | Array(Value) | Hash(String, Value)
end
