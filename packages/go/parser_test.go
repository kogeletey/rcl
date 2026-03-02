package rcl

import "testing"

func TestFullSpecParseAndFormat(t *testing.T) {
	src := "# comment\nserver do\n  host = \"localhost\"\n  port = 8080\n  ratio = 3.14\n  negative = -42\n  enabled = true\n  names = [\"a\", \"b\", 1, false]\n  tls.cert_path = \"/etc/cert.pem\"\n  region \"us-east\" do\n    replicas = 2\n  end\nend"
	doc, err := Parse(src)
	if err != nil { t.Fatalf("parse error: %v", err) }
	if doc.Kind() != "document" || len(doc.Blocks) != 1 { t.Fatalf("invalid document") }
	if doc.Blocks[0].Name != "server" { t.Fatalf("invalid block name") }
	obj := ToObject(doc)
	server, ok := obj["server"].(map[string]any)
	if !ok { t.Fatalf("server missing") }
	tls, ok := server["tls"].(map[string]any)
	if !ok || tls["cert_path"] != "/etc/cert.pem" { t.Fatalf("nested dotted key mismatch") }
	out, err := Format(doc)
	if err != nil { t.Fatalf("format error: %v", err) }
	reparsed, err := Parse(out)
	if err != nil || len(reparsed.Blocks) != len(doc.Blocks) { t.Fatalf("roundtrip failed") }
}

func TestNamedBlockObjectAndConversion(t *testing.T) {
	src := "config do\n  region \"us\" do\n    name = \"My name\"\n  end\nend"
	doc, err := Parse(src)
	if err != nil { t.Fatalf("parse error: %v", err) }
	obj := ToObject(doc)
	config, ok := obj["config"].(map[string]any)
	if !ok { t.Fatalf("config map missing") }
	regions, ok := config["regions"].(map[string]any)
	if !ok { t.Fatalf("regions map missing") }
	us, ok := regions["us"].(map[string]any)
	if !ok || us["name"] != "My name" { t.Fatalf("config.regions.us.name mismatch") }
	yaml, _ := ToYAML(doc)
	toml, _ := ToTOML(doc)
	hcl, _ := ToHCL(doc)
	if yaml == "" || toml == "" || hcl == "" { t.Fatalf("conversion output is empty") }
}

func TestErrorPosition(t *testing.T) {
	_, err := Parse("a do\n  x = [1,2\nend")
	if err == nil { t.Fatalf("expected error") }
	pe, ok := err.(*ParseError)
	if !ok || pe.Line <= 0 || pe.Column <= 0 { t.Fatalf("expected parse error with position") }
}

func TestStrictEdges(t *testing.T) {
	cases := []string{
		"x do\n  name = value\nend",
		"x do\n  arr = [1,]\nend",
		"x do\n  a = 1\n  a = 2\nend",
		"x do\n  a = 1\n  a.b = 2\nend",
	}
	for _, src := range cases {
		if _, err := Parse(src); err == nil { t.Fatalf("expected error for: %s", src) }
	}
}
