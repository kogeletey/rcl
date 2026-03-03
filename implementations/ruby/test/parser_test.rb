require "minitest/autorun"
require_relative "../lib/rcl"

class ParserTest < Minitest::Test
  def test_full_spec_parse_and_format
    src = [
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
      "end"
    ].join("\n")
    ast = RCL.parse(src)
    assert_equal "document", ast["kind"]
    assert_equal "server", ast["blocks"][0]["name"]
    out = RCL.format(ast)
    reparsed = RCL.parse(out)
    assert_equal ast, reparsed
  end

  def test_projection_and_converters
    src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend"
    obj = RCL.to_object(RCL.parse(src))
    assert_equal "My Name", obj["config"]["regions"]["us"]["name"]
    assert_includes RCL.to_yaml(RCL.parse(src)), "regions:"
    assert_includes RCL.to_toml(RCL.parse(src)), "[config.regions.us]"
    assert_includes RCL.to_hcl(RCL.parse(src)), "regions {"
  end

  def test_strict_edges
    bad = [
      "x do\n  name = value\nend",
      "x do\n  arr = [1,]\nend",
      "x do\n  a = 1\n  a = 2\nend",
      "x do\n  a = 1\n  a.b = 2\nend",
      "do [1] end",
      "x do\n  arr do [1]\n  y = 1\nend",
      "x do\n  name = 'bad'\nend",
      "x do\n  a = [1,2\nend"
    ]
    bad.each { |src| assert_raises(RuntimeError) { RCL.parse(src) } }
  end

  def test_named_array_root_array_and_anonymous_block_elements
    named_src = [
      "config do",
      "  tests do [",
      "    do",
      "      name = \"case-1\"",
      "    end,",
      "    \"string\"",
      "  ] end",
      "end"
    ].join("\n")
    named = RCL.to_object(RCL.parse(named_src))
    assert_equal "case-1", named["config"]["tests"][0]["name"]
    assert_equal "string", named["config"]["tests"][1]

    root_src = [
      "do [",
      "  do",
      "    name = \"root-item\"",
      "  end,",
      "  \"x\"",
      "]"
    ].join("\n")
    root = RCL.to_object(RCL.parse(root_src))
    assert_equal "root-item", root["root"][0]["name"]
    assert_equal "x", root["root"][1]
  end
end
