public enum Converters {
    public static func toObject(_ doc: DocumentNode) -> [String: Any] {
        var out: [String: Any] = [:]
        for b in doc.blocks {
            if let arg = b.argument { out[namedBase(b.name)] = [arg: blockToMap(b)] }
            else { out[b.name] = blockToMap(b) }
        }
        return out
    }

    public static func toYAML(_ doc: DocumentNode) -> String { emitYAML(toObject(doc), indent: 0) }
    public static func toTOML(_ doc: DocumentNode) -> String { emitTOML(toObject(doc)) }
    public static func toHCL(_ doc: DocumentNode) -> String { emitHCL(toObject(doc), indent: 0) }

    private static func blockToMap(_ block: BlockNode) -> [String: Any] {
        var result: [String: Any] = [:]
        for (k, v) in block.properties { insertPath(&result, key: k, value: nodeToAny(v)) }

        let children = uniqChildren(block)
        for child in children where child.argument == nil {
            var childMap = blockToMap(child)
            if let existing = result[child.name] as? [String: Any] {
                for (k, v) in existing { childMap[k] = v }
            }
            result[child.name] = childMap
        }
        for child in children where child.argument != nil {
            let base = namedBase(child.name)
            var parent = (result[base] as? [String: Any]) ?? [:]
            parent[child.argument!] = blockToMap(child)
            result[base] = parent
        }
        return result
    }

    private static func uniqChildren(_ block: BlockNode) -> [BlockNode] {
        var seen: Set<String> = []
        var out: [BlockNode] = []
        let mapped = block.blocks.values.sorted { lhs, rhs in
            let lk = lhs.argument != nil ? "\(lhs.name):\(lhs.argument!)" : lhs.name
            let rk = rhs.argument != nil ? "\(rhs.name):\(rhs.argument!)" : rhs.name
            return lk < rk
        }
        for c in mapped + block.namedBlocks {
            let key = c.argument != nil ? "\(c.name):\(c.argument!)" : c.name
            if seen.contains(key) { continue }
            seen.insert(key)
            out.append(c)
        }
        return out
    }

    private static func nodeToAny(_ node: Node) -> Any {
        switch node {
        case .string(let n): return n.value
        case .number(let n): return n.value
        case .boolean(let n): return n.value
        case .array(let n): return n.elements.map(nodeToAny)
        }
    }

    private static func emitYAML(_ value: Any, indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        if let map = value as? [String: Any] {
            return map.keys.sorted().map { k in
                let item = map[k]!
                if item is [String: Any] || item is [Any] { return "\(pad)\(k):\n\(emitYAML(item, indent: indent + 1))" }
                return "\(pad)\(k): \(scalar(item))"
            }.joined(separator: "\n")
        }
        if let arr = value as? [Any] {
            return arr.map { item in
                if item is [String: Any] || item is [Any] { return "\(pad)-\n\(emitYAML(item, indent: indent + 1))" }
                return "\(pad)- \(scalar(item))"
            }.joined(separator: "\n")
        }
        return "\(pad)\(scalar(value))"
    }

    private static func emitTOML(_ root: [String: Any]) -> String {
        var out: [String] = []
        func walk(_ obj: [String: Any], _ prefix: String?) {
            for k in obj.keys.sorted() { if !(obj[k] is [String: Any]) { out.append("\(k) = \(scalar(obj[k]!))") } }
            for k in obj.keys.sorted() {
                guard let child = obj[k] as? [String: Any] else { continue }
                let sec = prefix == nil ? k : "\(prefix!).\(k)"
                if !out.isEmpty { out.append("") }
                out.append("[\(sec)]")
                walk(child, sec)
            }
        }
        walk(root, nil)
        return out.joined(separator: "\n")
    }

    private static func emitHCL(_ value: Any, indent: Int) -> String {
        let pad = String(repeating: "  ", count: indent)
        guard let obj = value as? [String: Any] else { return "\(pad)\(scalar(value))" }
        return obj.keys.sorted().map { k in
            let item = obj[k]!
            if item is [String: Any] { return "\(pad)\(k) {\n\(emitHCL(item, indent: indent + 1))\n\(pad)}" }
            return "\(pad)\(k) = \(scalar(item))"
        }.joined(separator: "\n")
    }

    private static func scalar(_ value: Any) -> String {
        if let v = value as? String {
            return "\"\(v.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "\t", with: "\\t"))\""
        }
        if let v = value as? Bool { return v ? "true" : "false" }
        if let v = value as? Double { return "\(v)" }
        if let v = value as? [Any] { return "[\(v.map { scalar($0) }.joined(separator: ", "))]" }
        return "{}"
    }

    private static func insertPath(_ target: inout [String: Any], key: String, value: Any) {
        let parts = key.split(separator: ".").map(String.init)
        if parts.count == 1 {
            if target[parts[0]] != nil { fatalError("duplicate key") }
            target[parts[0]] = value
            return
        }
        let head = parts[0]
        if let current = target[head], !(current is [String: Any]) { fatalError("key conflict") }
        var branch = (target[head] as? [String: Any]) ?? [:]
        insertPath(&branch, key: parts.dropFirst().joined(separator: "."), value: value)
        target[head] = branch
    }

    private static func namedBase(_ name: String) -> String { name == "region" ? "regions" : name }
}
