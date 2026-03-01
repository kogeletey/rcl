# RCL AST Nodes

module XrayRCL
  abstract class ASTNode
  end

  class StringNode < ASTNode
    getter value : String
    def initialize(@value); end
  end

  class NumberNode < ASTNode
    getter value : Int32 | Int64 | Float64
    def initialize(@value); end
  end

  class BooleanNode < ASTNode
    getter value : Bool
    def initialize(@value); end
  end

  class ArrayNode < ASTNode
    getter elements : Array(ASTNode)
    def initialize(@elements); end
  end

  class BlockNode < ASTNode
    getter name : String
    getter properties : Hash(String, ASTNode)
    getter blocks : Hash(String, BlockNode)

    def initialize(@name, @properties = {} of String => ASTNode, @blocks = {} of String => BlockNode)
    end

    def []?(key : String) : ASTNode?
      @properties[key]? || @blocks[key]?
    end

    def []=(key : String, value : ASTNode)
      @properties[key] = value
    end
  end

  class ProgramNode < ASTNode
    getter blocks : Array(BlockNode)
    def initialize(@blocks = [] of BlockNode); end
  end
end
