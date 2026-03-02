package rcl

type Node map[string]any

type Document struct {
	Kind   string `json:"kind"`
	Blocks []Node `json:"blocks"`
}

func Parse(text string) (Document, error) {
	return Document{Kind: "document", Blocks: []Node{}}, nil
}

func Format(doc Document) (string, error) {
	return "", nil
}
