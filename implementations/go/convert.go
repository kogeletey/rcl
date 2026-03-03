package rcl

import (
	"bytes"
	"sort"
	"strings"

	"github.com/hashicorp/hcl/v2/hclwrite"
	"github.com/pelletier/go-toml/v2"
	"github.com/zclconf/go-cty/cty"
	"gopkg.in/yaml.v3"
)

func ToObject(doc DocumentNode) map[string]any {
	if doc.RootValue != nil {
		return map[string]any{"root": nodeToAny(doc.RootValue)}
	}
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
	case BlockNode:
		return blockToMap(v)
	default:
		return nil
	}
}

func ToYAML(doc DocumentNode) (string, error) {
	b, err := yaml.Marshal(ToObject(doc))
	if err != nil {
		return "", err
	}
	return strings.TrimSuffix(string(b), "\n"), nil
}

func ToTOML(doc DocumentNode) (string, error) {
	b, err := toml.Marshal(ToObject(doc))
	if err != nil {
		return "", err
	}
	return strings.TrimSuffix(string(b), "\n"), nil
}

func ToHCL(doc DocumentNode) (string, error) {
	f := hclwrite.NewEmptyFile()
	body := f.Body()
	writeHCLObject(body, ToObject(doc))
	return string(bytes.TrimSpace(f.Bytes())), nil
}

func writeHCLObject(body *hclwrite.Body, obj map[string]any) {
	for _, k := range sortedKeys(obj) {
		item := obj[k]
		if child, ok := item.(map[string]any); ok {
			block := body.AppendNewBlock(k, nil)
			writeHCLObject(block.Body(), child)
			continue
		}
		if v, ok := toCty(item); ok {
			body.SetAttributeValue(k, v)
		}
	}
}

func toCty(v any) (cty.Value, bool) {
	switch t := v.(type) {
	case string:
		return cty.StringVal(t), true
	case bool:
		return cty.BoolVal(t), true
	case float64:
		return cty.NumberFloatVal(t), true
	case int:
		return cty.NumberIntVal(int64(t)), true
	case int32:
		return cty.NumberIntVal(int64(t)), true
	case int64:
		return cty.NumberIntVal(t), true
	case []any:
		items := make([]cty.Value, 0, len(t))
		for _, e := range t {
			cv, ok := toCty(e)
			if !ok {
				return cty.NilVal, false
			}
			items = append(items, cv)
		}
		return cty.TupleVal(items), true
	case map[string]any:
		attrs := make(map[string]cty.Value, len(t))
		for _, k := range sortedKeys(t) {
			cv, ok := toCty(t[k])
			if !ok {
				return cty.NilVal, false
			}
			attrs[k] = cv
		}
		return cty.ObjectVal(attrs), true
	default:
		return cty.NilVal, false
	}
}

func sortedKeys(m map[string]any) []string { k := make([]string, 0, len(m)); for x := range m { k = append(k, x) }; sort.Strings(k); return k }
func namedBase(name string) string { if strings.HasSuffix(name, "s") { return name }; return name + "s" }

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
