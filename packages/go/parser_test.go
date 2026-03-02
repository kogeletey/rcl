package rcl

import "testing"

func TestParseScaffold(t *testing.T) {
	doc, err := Parse("xray do\nend")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if doc.Kind != "document" {
		t.Fatalf("expected document kind")
	}
}
