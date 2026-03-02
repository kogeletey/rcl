use crate::ast::{AstNode, BlockNode, DocumentNode};
use std::collections::BTreeSet;

pub fn format(doc: &DocumentNode) -> String {
    doc.blocks.iter().map(|b| format_block(b, 0)).collect::<Vec<_>>().join("\n\n")
}

fn q(s: &str) -> String {
    format!(
        "\"{}\"",
        s.replace('\\', "\\\\").replace('"', "\\\"").replace('\n', "\\n").replace('\t', "\\t")
    )
}

fn format_value(v: &AstNode) -> String {
    match v {
        AstNode::String { value, .. } => q(value),
        AstNode::Number { value, .. } => value.to_string(),
        AstNode::Boolean { value, .. } => if *value { "true".into() } else { "false".into() },
        AstNode::Array { elements, .. } => format!("[{}]", elements.iter().map(format_value).collect::<Vec<_>>().join(", ")),
    }
}

fn format_block(b: &BlockNode, indent: usize) -> String {
    let pad = "  ".repeat(indent);
    let mut lines = vec![if let Some(arg) = &b.argument { format!("{}{} {} do", pad, b.name, q(arg)) } else { format!("{}{} do", pad, b.name) }];

    for (k, v) in &b.properties { lines.push(format!("{}  {} = {}", pad, k, format_value(v))); }

    let mut seen = BTreeSet::new();
    for child in b.blocks.values() {
        let key = if let Some(arg) = &child.argument { format!("{}:{}", child.name, arg) } else { child.name.clone() };
        if seen.insert(key) { lines.push(format_block(child, indent + 1)); }
    }
    for child in &b.named_blocks {
        let key = if let Some(arg) = &child.argument { format!("{}:{}", child.name, arg) } else { child.name.clone() };
        if seen.insert(key) { lines.push(format_block(child, indent + 1)); }
    }

    lines.push(format!("{}end", pad));
    lines.join("\n")
}
