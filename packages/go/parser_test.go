package rcl

import "testing"

func TestFullSpecParseAndFormat(t *testing.T) {
	src := "# comment\nserver do\n  host = \"localhost\"\n  port = 8080\n  ratio = 3.14\n  negative = -42\n  enabled = true\n  names = [\"a\", \"b\", 1, false]\n  tls.cert_path = \"/etc/cert.pem\"\n  region \"us-east\" do\n    replicas = 2\n  end\nend"
	doc, err := Parse(src)
	if err != nil { t.Fatalf("parse error: %v", err) }
	if doc.Kind() != "document" || len(doc.Blocks) != 1 { t.Fatalf("invalid document") }
	if doc.Blocks[0].Name != "server" { t.Fatalf("invalid block name") }
	if _, ok := doc.Blocks[0].Properties["tls.cert_path"]; !ok { t.Fatalf("dotted key missing") }
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
	region, ok := obj["region"].(map[string]any)
	if !ok { t.Fatalf("region map missing") }
	us, ok := region["us"].(map[string]any)
	if !ok || us["name"] != "My name" { t.Fatalf("region.us.name mismatch") }
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
