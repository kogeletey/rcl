import Foundation

public enum Formatter {
    public static func format(_ doc: DocumentNode) -> String {
        doc.blocks.map { formatBlock($0, indent: 0) }.joined(separator: "\n\n")
    }

    private static func formatBlock(_ block: BlockNode, indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        let head = block.argument != nil
            ? "\(pad)\(block.name) \(q(block.argument!)) do"
            : "\(pad)\(block.name) do"
        var lines = [head]

        for (k, v) in block.properties { lines.append("\(pad)  \(k) = \(formatValue(v))") }

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
        }
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
