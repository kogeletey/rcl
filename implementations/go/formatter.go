package rcl

import (
	"sort"
	"strconv"
	"strings"
)

func Format(doc DocumentNode) (string, error) {
	out := []string{}
	for _, b := range doc.Blocks { out = append(out, formatBlock(b, 0)) }
	return strings.Join(out, "\n\n"), nil
}

func quote(s string) string {
	s = strings.ReplaceAll(s, "\\", "\\\\")
	s = strings.ReplaceAll(s, "\"", "\\\"")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\t", "\\t")
	return "\"" + s + "\""
}

func formatValue(n Node) string {
	switch v := n.(type) {
	case StringNode:
		return quote(v.Value)
	case NumberNode:
		return strconv.FormatFloat(v.Value, 'f', -1, 64)
	case BooleanNode:
		if v.Value { return "true" }
		return "false"
	case ArrayNode:
		parts := []string{}
		for _, e := range v.Elements { parts = append(parts, formatValue(e)) }
		return "[" + strings.Join(parts, ", ") + "]"
	default:
		return ""
	}
}

func formatBlock(b BlockNode, indent int) string {
	pad := strings.Repeat("  ", indent)
	head := pad + b.Name + " do"
	if b.Argument != nil { head = pad + b.Name + " " + quote(*b.Argument) + " do" }
	lines := []string{head}
	propKeys := make([]string, 0, len(b.Properties))
	for k := range b.Properties { propKeys = append(propKeys, k) }
	sort.Strings(propKeys)
	for _, k := range propKeys { lines = append(lines, pad+"  "+k+" = "+formatValue(b.Properties[k])) }
	seen := map[string]bool{}
	blockKeys := make([]string, 0, len(b.Blocks))
	for k := range b.Blocks { blockKeys = append(blockKeys, k) }
	sort.Strings(blockKeys)
	for _, mapKey := range blockKeys {
		child := b.Blocks[mapKey]
		childKey := child.Name
		if child.Argument != nil { childKey += ":" + *child.Argument }
		if seen[childKey] { continue }
		seen[childKey] = true
		lines = append(lines, formatBlock(child, indent+1))
	}
	for _, child := range b.NamedBlocks {
		childKey := child.Name
		if child.Argument != nil { childKey += ":" + *child.Argument }
		if seen[childKey] { continue }
		seen[childKey] = true
		lines = append(lines, formatBlock(child, indent+1))
	}
	lines = append(lines, pad+"end")
	return strings.Join(lines, "\n")
}
