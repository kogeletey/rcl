import XCTest
@testable import RCLParser

final class RCLParserTests: XCTestCase {
    func testCoreSurfaceParseAndObjectProjection() throws {
        let src = [
            "root do",
            "  service \"api\" do",
            "    title = \"My Name\"",
            "  end",
            "end",
        ].joined(separator: "\n")

        let ast = try RCLCore.parse(src)
        XCTAssertEqual(ast.kind, "document")
        let obj = RCLCore.toObject(ast)
        let root = obj["root"] as? [String: Any]
        let services = root?["services"] as? [String: Any]
        let api = services?["api"] as? [String: Any]
        XCTAssertEqual(api?["title"] as? String, "My Name")
    }

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
        let obj = RCL.toObject(ast)
        let server = obj["server"] as? [String: Any]
        let tls = server?["tls"] as? [String: Any]
        XCTAssertEqual(tls?["cert_path"] as? String, "/etc/cert.pem")

        let out = RCL.format(ast)
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
        let obj = RCL.toObject(ast)
        let config = obj["config"] as? [String: Any]
        let regions = config?["regions"] as? [String: Any]
        let us = regions?["us"] as? [String: Any]
        XCTAssertEqual(us?["name"] as? String, "My name")
        XCTAssertTrue(RCL.toYAML(ast).contains("regions:"))
        XCTAssertTrue(RCL.toTOML(ast).contains("[config.regions.us]"))
        XCTAssertTrue(RCL.toHCL(ast).contains("regions {"))
    }

    func testStrictEdges() {
        let bad = [
            "x do\n  name = value\nend",
            "x do\n  arr = [1,]\nend",
            "x do\n  a = 1\n  a = 2\nend",
            "x do\n  a = 1\n  a.b = 2\nend",
            "do [1] end",
            "x do\n  arr do [1]\n  y = 1\nend",
        ]
        for src in bad {
            XCTAssertThrowsError(try RCL.parse(src))
        }
    }

    func testNamedArrayRootArrayAndAnonymousBlockElements() throws {
        let namedSrc = [
            "config do",
            "  tests do [",
            "    do",
            "      name = \"case-1\"",
            "    end,",
            "    \"string\"",
            "  ] end",
            "end",
        ].joined(separator: "\n")
        let namedObj = RCL.toObject(try RCL.parse(namedSrc))
        let config = namedObj["config"] as? [String: Any]
        let tests = config?["tests"] as? [Any]
        let first = tests?[0] as? [String: Any]
        XCTAssertEqual(first?["name"] as? String, "case-1")
        XCTAssertEqual(tests?[1] as? String, "string")

        let rootSrc = [
            "do [",
            "  do",
            "    name = \"root-item\"",
            "  end,",
            "  \"x\"",
            "]",
        ].joined(separator: "\n")
        let rootObj = RCL.toObject(try RCL.parse(rootSrc))
        let root = rootObj["root"] as? [Any]
        let rootFirst = root?[0] as? [String: Any]
        XCTAssertEqual(rootFirst?["name"] as? String, "root-item")
        XCTAssertEqual(root?[1] as? String, "x")
    }
}
