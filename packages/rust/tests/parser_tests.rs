use rcl_parser::{format, parse};

#[test]
fn parse_and_format_full_spec() {
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
    ].join("\n");

    let doc = parse(&src).expect("parse");
    assert_eq!(doc.kind, "document");
    assert_eq!(doc.blocks[0].name, "server");

    let out = format(&doc);
    let reparsed = parse(&out).expect("reparse");
    assert_eq!(reparsed, doc);
}

#[test]
fn parse_error_position() {
    let err = parse("x do\n  a = [1,2\nend").expect_err("must fail");
    assert!(err.line > 0);
    assert!(err.column > 0);
}
