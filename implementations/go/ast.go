package rcl

type Node interface {
	Kind() string
}

type DocumentNode struct {
	NodeKind string      `json:"kind"`
	Blocks   []BlockNode `json:"blocks"`
	RootValue Node       `json:"root_value,omitempty"`
}

func (n DocumentNode) Kind() string { return n.NodeKind }

type BlockNode struct {
	NodeKind    string              `json:"kind"`
	Name        string              `json:"name"`
	Argument    *string             `json:"argument,omitempty"`
	Properties  map[string]Node     `json:"properties"`
	Blocks      map[string]BlockNode `json:"blocks"`
	NamedBlocks []BlockNode         `json:"named_blocks,omitempty"`
}

func (n BlockNode) Kind() string { return n.NodeKind }

type StringNode struct {
	NodeKind string `json:"kind"`
	Value    string `json:"value"`
}

func (n StringNode) Kind() string { return n.NodeKind }

type NumberNode struct {
	NodeKind string  `json:"kind"`
	Value    float64 `json:"value"`
}

func (n NumberNode) Kind() string { return n.NodeKind }

type BooleanNode struct {
	NodeKind string `json:"kind"`
	Value    bool   `json:"value"`
}

func (n BooleanNode) Kind() string { return n.NodeKind }

type ArrayNode struct {
	NodeKind string `json:"kind"`
	Elements []Node `json:"elements"`
}

func (n ArrayNode) Kind() string { return n.NodeKind }
