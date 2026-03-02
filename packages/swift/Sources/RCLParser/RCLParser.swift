public struct DocumentNode {
    public let kind: String
    public let blocks: [[String: Any]]

    public init(kind: String = "document", blocks: [[String: Any]] = []) {
        self.kind = kind
        self.blocks = blocks
    }
}

public enum RCLParser {
    public static func parse(_ text: String) throws -> DocumentNode {
        DocumentNode()
    }

    public static func format(_ document: DocumentNode) -> String {
        ""
    }
}
