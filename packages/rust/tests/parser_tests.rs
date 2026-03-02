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
    let obj = to_object(&doc);
    let server = match obj.get("server").expect("server") {
        rcl_parser::convert::Value::O(map) => map,
        _ => panic!("server map expected"),
    };
    let tls = match server.get("tls").expect("tls") {
        rcl_parser::convert::Value::O(map) => map,
        _ => panic!("tls map expected"),
    };
    assert_eq!(tls.get("cert_path"), Some(&rcl_parser::convert::Value::S("/etc/cert.pem".into())));

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
    let config = obj.get("config").expect("config");
    let us_name = match config {
        rcl_parser::convert::Value::O(map) => match map.get("regions").expect("regions") {
            rcl_parser::convert::Value::O(regions) => match regions.get("us").expect("us") {
                rcl_parser::convert::Value::O(us) => us.get("name").expect("name"),
                _ => panic!("us map expected"),
            },
            _ => panic!("regions map expected"),
        },
        _ => panic!("config map expected"),
    };
    assert_eq!(us_name, &rcl_parser::convert::Value::S("My name".into()));
    assert!(to_yaml(&doc).contains("regions:"));
    assert!(to_toml(&doc).contains("[config.regions.us]"));
    assert!(to_hcl(&doc).contains("regions {"));
}

#[test]
fn strict_edges() {
    let bad = [
        "x do\n  name = value\nend",
        "x do\n  arr = [1,]\nend",
        "x do\n  a = 1\n  a = 2\nend",
        "x do\n  a = 1\n  a.b = 2\nend",
    ];
    for src in bad {
        assert!(parse(src).is_err());
    }
}
