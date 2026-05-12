package core

import "testing"

func TestCoreParseAndToObject(t *testing.T) {
	src := "config do\n  region \"us\" do\n    name = \"My name\"\n  end\nend"
	doc, err := Parse(src)
	if err != nil {
		t.Fatalf("parse error: %v", err)
	}
	obj := ToObject(doc)
	config, ok := obj["config"].(map[string]any)
	if !ok {
		t.Fatalf("config map missing")
	}
	regions, ok := config["regions"].(map[string]any)
	if !ok {
		t.Fatalf("regions map missing")
	}
	us, ok := regions["us"].(map[string]any)
	if !ok || us["name"] != "My name" {
		t.Fatalf("config.regions.us.name mismatch")
	}
}
