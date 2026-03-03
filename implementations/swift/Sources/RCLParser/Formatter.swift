import Foundation

public enum Formatter {
    public static func format(_ doc: DocumentNode) -> String {
        if let root = doc.rootValue, root.kind == "array" { return "do \(formatValue(root))" }
        doc.blocks.map { formatBlock($0, indent: 0) }.joined(separator: "\n\n")
    }

    private static func formatBlock(_ block: BlockNode, indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        let head = block.argument != nil
            ? "\(pad)\(block.name) \(q(block.argument!)) do"
            : "\(pad)\(block.name) do"
        var lines = [head]

        for (k, v) in block.properties {
            if v.kind == "array" { lines.append("\(pad)  \(k) do \(formatValue(v)) end") }
            else { lines.append("\(pad)  \(k) = \(formatValue(v))") }
        }

        var seen = Set<String>()
        for child in block.blocks.values {
            let key = child.argument != nil ? "\(child.name):\(child.argument!)" : child.name
            if seen.insert(key).inserted { lines.append(formatBlock(child, indent: indent + 1)) }
        }
        for child in block.namedBlocks {
            let key = child.argument != nil ? "\(child.name):\(child.argument!)" : child.name
            if seen.insert(key).inserted { lines.append(formatBlock(child, indent: indent + 1)) }
        }

        lines.append("\(pad)end")
        return lines.joined(separator: "\n")
    }

    private static func formatValue(_ node: Node) -> String {
        switch node {
        case .string(let n): return q(n.value)
        case .number(let n): return "\(n.value)"
        case .boolean(let n): return n.value ? "true" : "false"
        case .array(let n): return "[\(n.elements.map { formatValue($0) }.joined(separator: ", "))]"
        case .block(let n): return formatAnonymousBlock(n)
        }
    }

    private static func formatAnonymousBlock(_ block: BlockNode) -> String {
        var parts: [String] = []
        for (k, v) in block.properties { parts.append("\(k) = \(formatValue(v))") }
        for child in block.blocks.values { parts.append(formatInlineBlock(child)) }
        for child in block.namedBlocks { parts.append(formatInlineBlock(child)) }
        return parts.isEmpty ? "do end" : "do \(parts.joined(separator: " ")) end"
    }

    private static func formatInlineBlock(_ block: BlockNode) -> String {
        let head = block.argument != nil ? "\(block.name) \(q(block.argument!)) do" : "\(block.name) do"
        var parts: [String] = []
        for (k, v) in block.properties { parts.append("\(k) = \(formatValue(v))") }
        for child in block.blocks.values { parts.append(formatInlineBlock(child)) }
        for child in block.namedBlocks { parts.append(formatInlineBlock(child)) }
        return parts.isEmpty ? "\(head) end" : "\(head) \(parts.joined(separator: " ")) end"
    }

    private static func q(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"\(escaped)\""
    }
}
