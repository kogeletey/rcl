use rcl_parser::{format, parse, to_hcl, to_object, to_toml, to_yaml};

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

#[test]
fn named_block_and_conversion() {
    let src = [
        "config do",
        "  region \"us\" do",
        "    name = \"My name\"",
        "  end",
        "end",
    ].join("\n");
    let doc = parse(&src).expect("parse");
    let obj = to_object(&doc);
    let region = obj.get("region").expect("region");
    let us_name = match region {
        rcl_parser::convert::Value::O(map) => match map.get("us").expect("us") {
            rcl_parser::convert::Value::O(us) => us.get("name").expect("name"),
            _ => panic!("us map expected"),
        },
        _ => panic!("region map expected"),
    };
    assert_eq!(us_name, &rcl_parser::convert::Value::S("My name".into()));
    assert!(to_yaml(&doc).contains("region:"));
    assert!(to_toml(&doc).contains("[region.us]"));
    assert!(to_hcl(&doc).contains("region {"));
}
