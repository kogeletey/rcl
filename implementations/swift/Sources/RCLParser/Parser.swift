public final class Parser {
    private let lexer: Lexer
    private var current: Token

    public init(_ text: String) throws {
        self.lexer = Lexer(text)
        self.current = try lexer.nextToken()
    }

    public func parse() throws -> DocumentNode {
        if current.type == .do {
            try eat(.do)
            let rootValue = try parseArray()
            if current.type != .eof { throw err("unexpected token after root array") }
            return DocumentNode(blocks: [], rootValue: rootValue)
        }
        var blocks: [BlockNode] = []
        while current.type != .eof { blocks.append(try parseBlock()) }
        return DocumentNode(blocks: blocks)
    }

    private func parseBlock() throws -> BlockNode {
        let name = current.value
        try eat(.identifier)
        var argument: String?
        if current.type == .string { argument = current.value; try eat(.string) }
        try eat(.do)

        let out = try parseBlockBody(name: name, argument: argument)
        try eat(.end)
        return out
    }

    private func parseAnonymousBlock() throws -> BlockNode {
        try eat(.do)
        let out = try parseBlockBody(name: "", argument: nil)
        try eat(.end)
        return out
    }

    private func parseBlockBody(name: String, argument: String?) throws -> BlockNode {
        var properties: [String: Node] = [:]
        var blocks: [String: BlockNode] = [:]
        var named: [BlockNode] = []
        var seen: Set<String> = []

        while current.type != .end {
            if current.type == .eof { throw err("missing end") }
            if current.type != .identifier { throw err("expected identifier") }
            let next = try peekToken()
            if next.type == .do {
                let afterDo = try peekToken(offset: 2)
                if afterDo.type == .lbracket {
                    let key = current.value
                    try eat(.identifier)
                    try ensureKeyValid(key, seen: &seen)
                    try eat(.do)
                    properties[key] = try parseArray()
                    try eat(.end)
                } else {
                    let child = try parseBlock()
                    if child.argument != nil { named.append(child) }
                    else { blocks[child.name] = child }
                }
            } else if next.type == .string {
                let child = try parseBlock()
                if child.argument != nil { named.append(child) }
                else { blocks[child.name] = child }
            } else if next.type == .equal || next.type == .dot {
                let key = try parsePropertyKey()
                try ensureKeyValid(key, seen: &seen)
                try eat(.equal)
                properties[key] = try parseValue()
            } else { throw err("invalid statement") }
        }

        return BlockNode(name: name, argument: argument, properties: properties, blocks: blocks, namedBlocks: named)
    }

    private func parsePropertyKey() throws -> String {
        var key = current.value
        try eat(.identifier)
        while current.type == .dot {
            try eat(.dot)
            if current.type != .identifier { throw err("expected identifier after dot") }
            key += ".\(current.value)"
            try eat(.identifier)
        }
        return key
    }

    private func parseValue() throws -> Node {
        switch current.type {
        case .string: let v = current.value; try eat(.string); return .string(StringNode(value: v))
        case .number: let v = Double(current.value) ?? 0; try eat(.number); return .number(NumberNode(value: v))
        case .identifier:
            let v = current.value; try eat(.identifier)
            if v == "true" { return .boolean(BooleanNode(value: true)) }
            if v == "false" { return .boolean(BooleanNode(value: false)) }
            throw err("invalid bare value")
        case .lbracket: return try parseArray()
        case .do: return .block(try parseAnonymousBlock())
        default: throw err("unexpected value")
        }
    }

    private func parseArray() throws -> Node {
        try eat(.lbracket)
        var elements: [Node] = []
        if current.type != .rbracket {
            elements.append(try parseValue())
            while current.type == .comma {
                try eat(.comma)
                if current.type == .rbracket { throw err("trailing comma in array") }
                elements.append(try parseValue())
            }
        }
        try eat(.rbracket)
        return .array(ArrayNode(elements: elements))
    }

    private func eat(_ type: TokenType) throws {
        if current.type != type { throw err("expected \(type), got \(current.type)") }
        current = try lexer.nextToken()
    }

    private func peekToken(offset: Int = 1) throws -> Token {
        let st = lexer.snapshot()
        var tok = current
        for _ in 0..<offset { tok = try lexer.nextToken() }
        lexer.restore(st)
        return tok
    }

    private func err(_ message: String) -> ParseError { ParseError(message, line: current.line, column: current.column) }

    private func ensureKeyValid(_ key: String, seen: inout Set<String>) throws {
        if seen.contains(key) { throw err("duplicate key") }
        let parts = key.split(separator: ".").map(String.init)
        for existing in seen {
            let ex = existing.split(separator: ".").map(String.init)
            if isPrefix(parts, ex) || isPrefix(ex, parts) { throw err("key conflict") }
        }
        seen.insert(key)
    }

    private func isPrefix(_ left: [String], _ right: [String]) -> Bool {
        if left.count >= right.count { return false }
        for i in 0..<left.count where left[i] != right[i] { return false }
        return true
    }
}

public enum RCL {
    public static func parse(_ text: String) throws -> DocumentNode { try RCLCore.parse(text) }
    public static func format(_ text: String) throws -> String { format(try parse(text)) }
    public static func format(_ doc: DocumentNode) -> String { Formatter.format(doc) }
    public static func toObject(_ text: String) throws -> [String: Any] { try toObject(parse(text)) }
    public static func toObject(_ doc: DocumentNode) -> [String: Any] { RCLCore.toObject(doc) }
    public static func toYAML(_ text: String) throws -> String { toYAML(try parse(text)) }
    public static func toYAML(_ doc: DocumentNode) -> String { Converters.toYAML(doc) }
    public static func toTOML(_ text: String) throws -> String { toTOML(try parse(text)) }
    public static func toTOML(_ doc: DocumentNode) -> String { Converters.toTOML(doc) }
    public static func toHCL(_ text: String) throws -> String { toHCL(try parse(text)) }
    public static func toHCL(_ doc: DocumentNode) -> String { Converters.toHCL(doc) }
}
