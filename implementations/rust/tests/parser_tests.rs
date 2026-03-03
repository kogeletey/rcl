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

#[test]
fn array_features() {
    let named = r#"config do
  tests do [
    do
      name = "case-1"
    end,
    "string"
  ] end
end"#;
    let doc = parse(named).expect("parse named array");
    let obj = to_object(&doc);
    let cfg = match obj.get("config").expect("config") {
        rcl_parser::convert::Value::O(v) => v,
        _ => panic!("config type"),
    };
    let tests = match cfg.get("tests").expect("tests") {
        rcl_parser::convert::Value::A(v) => v,
        _ => panic!("tests type"),
    };
    let first = match &tests[0] {
        rcl_parser::convert::Value::O(v) => v,
        _ => panic!("first type"),
    };
    assert_eq!(first.get("name"), Some(&rcl_parser::convert::Value::S("case-1".to_string())));
    assert_eq!(tests[1], rcl_parser::convert::Value::S("string".to_string()));

    let root = r#"do [
  do
    name = "root-item"
  end,
  "x"
]"#;
    let root_doc = parse(root).expect("parse root array");
    let root_obj = to_object(&root_doc);
    let root_arr = match root_obj.get("root").expect("root") {
        rcl_parser::convert::Value::A(v) => v,
        _ => panic!("root type"),
    };
    let root_first = match &root_arr[0] {
        rcl_parser::convert::Value::O(v) => v,
        _ => panic!("root first"),
    };
    assert_eq!(root_first.get("name"), Some(&rcl_parser::convert::Value::S("root-item".to_string())));
    assert_eq!(root_arr[1], rcl_parser::convert::Value::S("x".to_string()));
}
