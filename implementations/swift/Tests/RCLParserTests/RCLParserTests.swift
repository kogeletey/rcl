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
        let obj = Converters.toObject(ast)
        let server = obj["server"] as? [String: Any]
        let tls = server?["tls"] as? [String: Any]
        XCTAssertEqual(tls?["cert_path"] as? String, "/etc/cert.pem")

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
        let config = obj["config"] as? [String: Any]
        let regions = config?["regions"] as? [String: Any]
        let us = regions?["us"] as? [String: Any]
        XCTAssertEqual(us?["name"] as? String, "My name")
        XCTAssertTrue(Converters.toYAML(ast).contains("regions:"))
        XCTAssertTrue(Converters.toTOML(ast).contains("[config.regions.us]"))
        XCTAssertTrue(Converters.toHCL(ast).contains("regions {"))
    }

    func testStrictEdges() {
        let bad = [
            "x do\n  name = value\nend",
            "x do\n  arr = [1,]\nend",
            "x do\n  a = 1\n  a = 2\nend",
            "x do\n  a = 1\n  a.b = 2\nend",
        ]
        for src in bad {
            XCTAssertThrowsError(try RCL.parse(src))
        }
    }
}
