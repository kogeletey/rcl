import XCTest
@testable import RCLParser

final class RCLParserTests: XCTestCase {
    func testParseAndFormatFullSpec() throws {
        let src = [
            "# comment",
            "server do",
            "  host = \"localhost\"",
            "  port = 8080",
            "  ratio = 3.14",
            "  negative = -42",
            "  enabled = true",
            "  names = [\"a\", \"b\", 1, false]",
            "  tls.cert_path = \"/etc/cert.pem\"",
            "  region \"us-east\" do",
            "    replicas = 2",
            "  end",
            "end",
        ].joined(separator: "\n")

        let ast = try RCL.parse(src)
        XCTAssertEqual(ast.kind, "document")
        XCTAssertEqual(ast.blocks.first?.name, "server")

        let out = Formatter.format(ast)
        let reparsed = try RCL.parse(out)
        XCTAssertEqual(reparsed, ast)
    }

    func testErrorHasPosition() {
        XCTAssertThrowsError(try RCL.parse("x do\n  a = [1,2\nend")) { error in
            guard let pe = error as? ParseError else { return XCTFail("wrong error") }
            XCTAssertGreaterThan(pe.line, 0)
            XCTAssertGreaterThan(pe.column, 0)
        }
    }

    func testNamedBlockAndConverters() throws {
        let src = [
            "config do",
            "  region \"us\" do",
            "    name = \"My name\"",
            "  end",
            "end",
        ].joined(separator: "\n")

        let ast = try RCL.parse(src)
        let obj = Converters.toObject(ast)
        let region = obj["region"] as? [String: Any]
        let us = region?["us"] as? [String: Any]
        XCTAssertEqual(us?["name"] as? String, "My name")
        XCTAssertTrue(Converters.toYAML(ast).contains("region:"))
        XCTAssertTrue(Converters.toTOML(ast).contains("[region.us]"))
        XCTAssertTrue(Converters.toHCL(ast).contains("region {"))
    }
}
