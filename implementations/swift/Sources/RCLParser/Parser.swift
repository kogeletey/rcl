public final class Parser {
    private let lexer: Lexer
    private var current: Token

    public init(_ text: String) throws {
        self.lexer = Lexer(text)
        self.current = try lexer.nextToken()
    }

    public func parse() throws -> DocumentNode {
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

        var properties: [String: Node] = [:]
        var blocks: [String: BlockNode] = [:]
        var named: [BlockNode] = []
        var seen: Set<String> = []

        while current.type != .end {
            if current.type == .eof { throw err("missing end") }
            if current.type != .identifier { throw err("expected identifier") }
            let next = try peekToken()
            if next.type == .do || next.type == .string {
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

        try eat(.end)
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

    private func peekToken() throws -> Token {
        let st = lexer.snapshot()
        let tok = try lexer.nextToken()
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
    public static func parse(_ text: String) throws -> DocumentNode { try Parser(text).parse() }
}
