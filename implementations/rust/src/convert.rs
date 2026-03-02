use std::collections::{BTreeMap, BTreeSet};

use crate::ast::{AstNode, BlockNode, DocumentNode};

#[derive(Clone, Debug, PartialEq)]
pub enum Value { S(String), N(f64), B(bool), A(Vec<Value>), O(BTreeMap<String, Value>) }

pub fn to_object(doc: &DocumentNode) -> BTreeMap<String, Value> {
    let mut out = BTreeMap::new();
    for b in &doc.blocks {
        if let Some(arg) = &b.argument {
            let mut arg_map = BTreeMap::new();
            arg_map.insert(arg.clone(), Value::O(block_to_map(b)));
            out.insert(named_base(&b.name), Value::O(arg_map));
        } else {
            out.insert(b.name.clone(), Value::O(block_to_map(b)));
        }
    }
    out
}

pub fn to_yaml(doc: &DocumentNode) -> String { emit_yaml(&Value::O(to_object(doc)), 0) }
pub fn to_toml(doc: &DocumentNode) -> String { emit_toml(&to_object(doc)) }
pub fn to_hcl(doc: &DocumentNode) -> String { emit_hcl(&Value::O(to_object(doc)), 0) }

fn block_to_map(block: &BlockNode) -> BTreeMap<String, Value> {
    let mut out = BTreeMap::new();
    for (k, v) in &block.properties { insert_path(&mut out, k, node_to_value(v)); }

    let children = uniq_children(block);
    for c in children.iter().filter(|x| x.argument.is_none()) {
        let mut child = block_to_map(c);
        if let Some(Value::O(existing)) = out.get(&c.name) {
            for (k, v) in existing { child.insert(k.clone(), v.clone()); }
        }
        out.insert(c.name.clone(), Value::O(child));
    }
    for c in children.iter().filter(|x| x.argument.is_some()) {
        let arg = c.argument.clone().unwrap_or_default();
        let base = named_base(&c.name);
        let mut parent = match out.get(&base) { Some(Value::O(v)) => v.clone(), _ => BTreeMap::new() };
        parent.insert(arg, Value::O(block_to_map(c)));
        out.insert(base, Value::O(parent));
    }
    out
}

fn uniq_children(block: &BlockNode) -> Vec<BlockNode> {
    let mut out = Vec::new();
    let mut seen = BTreeSet::new();
    for c in block.blocks.values().chain(block.named_blocks.iter()) {
        let id = if let Some(a) = &c.argument { format!("{}:{}", c.name, a) } else { c.name.clone() };
        if seen.insert(id) { out.push(c.clone()); }
    }
    out
}

fn node_to_value(node: &AstNode) -> Value {
    match node {
        AstNode::String { value, .. } => Value::S(value.clone()),
        AstNode::Number { value, .. } => Value::N(*value),
        AstNode::Boolean { value, .. } => Value::B(*value),
        AstNode::Array { elements, .. } => Value::A(elements.iter().map(node_to_value).collect()),
    }
}

fn emit_yaml(v: &Value, indent: usize) -> String {
    let pad = "  ".repeat(indent);
    match v {
        Value::O(map) => map.iter().map(|(k, item)| {
            if matches!(item, Value::O(_) | Value::A(_)) { format!("{}{}:\n{}", pad, k, emit_yaml(item, indent + 1)) }
            else { format!("{}{}: {}", pad, k, scalar(item)) }
        }).collect::<Vec<_>>().join("\n"),
        Value::A(arr) => arr.iter().map(|item| {
            if matches!(item, Value::O(_) | Value::A(_)) { format!("{}-\n{}", pad, emit_yaml(item, indent + 1)) }
            else { format!("{}- {}", pad, scalar(item)) }
        }).collect::<Vec<_>>().join("\n"),
        _ => format!("{}{}", pad, scalar(v)),
    }
}

fn emit_toml(root: &BTreeMap<String, Value>) -> String {
    let mut out = Vec::new();
    fn walk(obj: &BTreeMap<String, Value>, prefix: Option<String>, out: &mut Vec<String>) {
        for (k, v) in obj { if !matches!(v, Value::O(_)) { out.push(format!("{} = {}", k, scalar(v))); } }
        for (k, v) in obj {
            let Value::O(child) = v else { continue };
            let sec = prefix.as_ref().map(|p| format!("{}.{}", p, k)).unwrap_or_else(|| k.clone());
            if !out.is_empty() { out.push(String::new()); }
            out.push(format!("[{}]", sec));
            walk(child, Some(sec), out);
        }
    }
    walk(root, None, &mut out);
    out.join("\n")
}

fn emit_hcl(v: &Value, indent: usize) -> String {
    let pad = "  ".repeat(indent);
    let Value::O(obj) = v else { return format!("{}{}", pad, scalar(v)) };
    obj.iter().map(|(k, item)| {
        if let Value::O(_) = item { format!("{}{} {{\n{}\n{}}}", pad, k, emit_hcl(item, indent + 1), pad) }
        else { format!("{}{} = {}", pad, k, scalar(item)) }
    }).collect::<Vec<_>>().join("\n")
}

fn scalar(v: &Value) -> String {
    match v {
        Value::S(s) => format!("\"{}\"", s.replace('\\', "\\\\").replace('"', "\\\"").replace('\n', "\\n").replace('\t', "\\t")),
        Value::N(n) => n.to_string(),
        Value::B(b) => if *b { "true".into() } else { "false".into() },
        Value::A(a) => format!("[{}]", a.iter().map(scalar).collect::<Vec<_>>().join(", ")),
        Value::O(_) => "{}".into(),
    }
}

fn insert_path(target: &mut BTreeMap<String, Value>, key: &str, value: Value) {
    let parts: Vec<&str> = key.split('.').collect();
    if parts.len() == 1 {
        if target.contains_key(key) { panic!("duplicate key"); }
        target.insert(key.to_string(), value);
        return;
    }
    let head = parts[0].to_string();
    let branch = match target.get(&head) {
        Some(Value::O(v)) => v.clone(),
        Some(_) => panic!("key conflict"),
        None => BTreeMap::new(),
    };
    let mut next = branch;
    insert_path(&mut next, &parts[1..].join("."), value);
    target.insert(head, Value::O(next));
}

fn named_base(name: &str) -> String {
    if name == "region" { "regions".to_string() } else { name.to_string() }
}
