use std::collections::BTreeMap;

#[derive(Clone, Debug, PartialEq)]
pub struct DocumentNode {
    pub kind: &'static str,
    pub blocks: Vec<BlockNode>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct BlockNode {
    pub kind: &'static str,
    pub name: String,
    pub argument: Option<String>,
    pub properties: BTreeMap<String, AstNode>,
    pub blocks: BTreeMap<String, BlockNode>,
    pub named_blocks: Vec<BlockNode>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum AstNode {
    String { kind: &'static str, value: String },
    Number { kind: &'static str, value: f64 },
    Boolean { kind: &'static str, value: bool },
    Array { kind: &'static str, elements: Vec<AstNode> },
}
