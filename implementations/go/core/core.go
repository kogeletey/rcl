package core

import rcl "github.com/rcl/parser-go"

type (
	Node        = rcl.Node
	DocumentNode = rcl.DocumentNode
	BlockNode   = rcl.BlockNode
	StringNode  = rcl.StringNode
	NumberNode  = rcl.NumberNode
	BooleanNode = rcl.BooleanNode
	ArrayNode   = rcl.ArrayNode
	ParseError  = rcl.ParseError
)

func Parse(text string) (DocumentNode, error) {
	return rcl.Parse(text)
}

func ToObject(doc DocumentNode) map[string]any {
	return rcl.ToObject(doc)
}
