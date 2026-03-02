import XCTest
@testable import RCLParser

final class RCLParserTests: XCTestCase {
    func testParseScaffold() throws {
        let doc = try RCLParser.parse("xray do\nend")
        XCTAssertEqual(doc.kind, "document")
    }
}
