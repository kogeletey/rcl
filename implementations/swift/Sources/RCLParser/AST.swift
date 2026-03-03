public enum Node: Equatable {
    case string(StringNode)
    case number(NumberNode)
    case boolean(BooleanNode)
    case array(ArrayNode)
    case block(BlockNode)

    public var kind: String {
        switch self {
        case .string: return "string"
        case .number: return "number"
        case .boolean: return "boolean"
        case .array: return "array"
        case .block: return "block"
        }
    }
}

public struct DocumentNode: Equatable {
    public let kind: String
    public let blocks: [BlockNode]
    public let rootValue: Node?

    public init(kind: String = "document", blocks: [BlockNode], rootValue: Node? = nil) {
        self.kind = kind
        self.blocks = blocks
        self.rootValue = rootValue
    }
}

public struct BlockNode: Equatable {
    public let kind: String
    public let name: String
    public let argument: String?
    public let properties: [String: Node]
    public let blocks: [String: BlockNode]
    public let namedBlocks: [BlockNode]

    public init(
        kind: String = "block",
        name: String,
        argument: String? = nil,
        properties: [String: Node] = [:],
        blocks: [String: BlockNode] = [:],
        namedBlocks: [BlockNode] = []
    ) {
        self.kind = kind
        self.name = name
        self.argument = argument
        self.properties = properties
        self.blocks = blocks
        self.namedBlocks = namedBlocks
    }
}

public struct StringNode: Equatable { public let kind: String = "string"; public let value: String }
public struct NumberNode: Equatable { public let kind: String = "number"; public let value: Double }
public struct BooleanNode: Equatable { public let kind: String = "boolean"; public let value: Bool }
public struct ArrayNode: Equatable { public let kind: String = "array"; public let elements: [Node] }

public struct ParseError: Error {
    public let message: String
    public let line: Int
    public let column: Int

    public init(_ message: String, line: Int, column: Int) {
        self.message = message
        self.line = line
        self.column = column
    }
}
