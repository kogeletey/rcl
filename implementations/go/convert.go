package rcl

import (
	"sort"
	"strconv"
	"strings"
)

func ToObject(doc DocumentNode) map[string]any {
	out := map[string]any{}
	for _, b := range doc.Blocks {
		if b.Argument != nil {
			out[namedBase(b.Name)] = map[string]any{*b.Argument: blockToMap(b)}
		} else {
			out[b.Name] = blockToMap(b)
		}
	}
	return out
}

func blockToMap(block BlockNode) map[string]any {
	result := map[string]any{}
	for k, v := range block.Properties { insertPath(result, k, nodeToAny(v)) }

	children := uniqChildren(block)
	for _, child := range children {
		if child.Argument != nil { continue }
		childObj := blockToMap(child)
		if existing, ok := result[child.Name].(map[string]any); ok {
			for k, v := range existing { childObj[k] = v }
		}
		result[child.Name] = childObj
	}
	for _, child := range children {
		if child.Argument == nil { continue }
		arg := *child.Argument
		base := namedBase(child.Name)
		parent, ok := result[base].(map[string]any)
		if !ok { parent = map[string]any{} }
		parent[arg] = blockToMap(child)
		result[base] = parent
	}
	return result
}

func uniqChildren(block BlockNode) []BlockNode {
	keys := make([]string, 0, len(block.Blocks))
	for k := range block.Blocks { keys = append(keys, k) }
	sort.Strings(keys)
	seen := map[string]bool{}
	out := []BlockNode{}
	for _, k := range keys {
		c := block.Blocks[k]
		id := c.Name
		if c.Argument != nil { id += ":" + *c.Argument }
		if seen[id] { continue }
		seen[id] = true
		out = append(out, c)
	}
	for _, c := range block.NamedBlocks {
		id := c.Name
		if c.Argument != nil { id += ":" + *c.Argument }
		if seen[id] { continue }
		seen[id] = true
		out = append(out, c)
	}
	return out
}

func nodeToAny(n Node) any {
	switch v := n.(type) {
	case StringNode:
		return v.Value
	case NumberNode:
		return v.Value
	case BooleanNode:
		return v.Value
	case ArrayNode:
		arr := make([]any, 0, len(v.Elements))
		for _, e := range v.Elements { arr = append(arr, nodeToAny(e)) }
		return arr
	default:
		return nil
	}
}

func ToYAML(doc DocumentNode) (string, error) { return emitYAML(ToObject(doc), 0), nil }
func ToTOML(doc DocumentNode) (string, error) { return emitTOML(ToObject(doc)), nil }
func ToHCL(doc DocumentNode) (string, error) { return emitHCL(ToObject(doc), 0), nil }

func emitYAML(v any, indent int) string {
	pad := strings.Repeat("  ", indent)
	switch t := v.(type) {
	case map[string]any:
		keys := sortedKeys(t); lines := []string{}
		for _, k := range keys {
			item := t[k]
			switch item.(type) {
			case map[string]any, []any:
				lines = append(lines, pad+k+":", emitYAML(item, indent+1))
			default:
				lines = append(lines, pad+k+": "+scalar(item))
			}
		}
		return strings.Join(lines, "\n")
	case []any:
		lines := []string{}
		for _, item := range t {
			switch item.(type) {
			case map[string]any, []any:
				lines = append(lines, pad+"-", emitYAML(item, indent+1))
			default:
				lines = append(lines, pad+"- "+scalar(item))
			}
		}
		return strings.Join(lines, "\n")
	default:
		return pad + scalar(v)
	}
}

func emitTOML(v map[string]any) string {
	out := []string{}
	var walk func(map[string]any, string)
	walk = func(obj map[string]any, prefix string) {
		for _, k := range sortedKeys(obj) { if _, ok := obj[k].(map[string]any); !ok { out = append(out, k+" = "+scalar(obj[k])) } }
		for _, k := range sortedKeys(obj) {
			child, ok := obj[k].(map[string]any); if !ok { continue }
			sec := k; if prefix != "" { sec = prefix + "." + k }
			if len(out) > 0 { out = append(out, "") }
			out = append(out, "["+sec+"]")
			walk(child, sec)
		}
	}
	walk(v, "")
	return strings.Join(out, "\n")
}

func emitHCL(v any, indent int) string {
	pad := strings.Repeat("  ", indent)
	obj, ok := v.(map[string]any)
	if !ok { return pad + scalar(v) }
	lines := []string{}
		for _, k := range sortedKeys(obj) {
			item := obj[k]
			if child, ok := item.(map[string]any); ok {
				lines = append(lines, pad+k+" {", emitHCL(child, indent+1), pad+"}")
			} else {
				lines = append(lines, pad+k+" = "+scalar(item))
			}
		}
		return strings.Join(lines, "\n")
	}

func sortedKeys(m map[string]any) []string { k := make([]string, 0, len(m)); for x := range m { k = append(k, x) }; sort.Strings(k); return k }
func scalar(v any) string {
	switch t := v.(type) {
	case string:
		r := strings.NewReplacer("\\", "\\\\", "\"", "\\\"", "\n", "\\n", "\t", "\\t")
		return "\"" + r.Replace(t) + "\""
	case bool:
		if t { return "true" }; return "false"
	case float64:
		return strconv.FormatFloat(t, 'f', -1, 64)
	case int, int32, int64:
		return strconv.FormatInt(reflectInt64(t), 10)
	case []any:
		parts := make([]string, 0, len(t)); for _, x := range t { parts = append(parts, scalar(x)) }; return "[" + strings.Join(parts, ", ") + "]"
	default:
		return "{}"
	}
}

func reflectInt64(v any) int64 { switch n := v.(type) { case int: return int64(n); case int32: return int64(n); case int64: return n; default: return 0 } }
func namedBase(name string) string { if name == "region" { return "regions" }; return name }

func insertPath(target map[string]any, key string, value any) {
	parts := strings.Split(key, ".")
	if len(parts) == 1 {
		if _, ok := target[key]; ok { panic("duplicate key") }
		target[key] = value
		return
	}
	head := parts[0]
	current, ok := target[head]
	if ok {
		if _, ok = current.(map[string]any); !ok { panic("key conflict") }
	}
	branch, _ := current.(map[string]any)
	if branch == nil { branch = map[string]any{} }
	insertPath(branch, strings.Join(parts[1:], "."), value)
	target[head] = branch
}
