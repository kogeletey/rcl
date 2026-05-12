import Foundation

public enum RCLCore {
    public static func parse(_ text: String) throws -> DocumentNode { try Parser(text).parse() }
    public static func toObject(_ text: String) throws -> [String: Any] { try toObject(parse(text)) }
    public static func toObject(_ doc: DocumentNode) -> [String: Any] { Converters.toObject(doc) }
}
