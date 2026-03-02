use std::collections::BTreeMap;

use crate::ast::{AstNode, BlockNode, DocumentNode};
use crate::error::ParseError;
use crate::lexer::{Lexer, Token, TokenType};

pub struct Parser { lex: Lexer, cur: Token }

impl Parser {
    pub fn new(text: &str) -> Result<Self, ParseError> {
        let mut lex = Lexer::new(text);
        let cur = lex.next_token()?;
        Ok(Self { lex, cur })
    }

    pub fn parse(&mut self) -> Result<DocumentNode, ParseError> {
        let mut blocks = Vec::new();
        while self.cur.typ != TokenType::Eof { blocks.push(self.parse_block()?); }
        Ok(DocumentNode { kind: "document", blocks })
    }

    fn parse_block(&mut self) -> Result<BlockNode, ParseError> {
        let name = self.cur.value.clone(); self.eat(TokenType::Identifier)?;
        let argument = if self.cur.typ == TokenType::String { let v = self.cur.value.clone(); self.eat(TokenType::String)?; Some(v) } else { None };
        self.eat(TokenType::Do)?;

        let mut properties = BTreeMap::new();
        let mut blocks = BTreeMap::new();
        let mut named_blocks = Vec::new();
        let mut seen = Vec::<String>::new();

        while self.cur.typ != TokenType::End {
            if self.cur.typ == TokenType::Eof { return Err(self.err("missing end")); }
            if self.cur.typ != TokenType::Identifier { return Err(self.err("expected identifier")); }
            let next = self.peek_token()?;
            if next.typ == TokenType::Do || next.typ == TokenType::String {
                let child = self.parse_block()?;
                if child.argument.is_some() {
                    named_blocks.push(child.clone());
                } else { blocks.insert(child.name.clone(), child); }
            } else if next.typ == TokenType::Equal || next.typ == TokenType::Dot {
                let key = self.parse_key()?;
                self.ensure_key_valid(&key, &seen)?;
                seen.push(key.clone());
                self.eat(TokenType::Equal)?;
                properties.insert(key, self.parse_value()?);
            } else { return Err(self.err("invalid statement")); }
        }
        self.eat(TokenType::End)?;
        Ok(BlockNode { kind: "block", name, argument, properties, blocks, named_blocks })
    }

    fn parse_key(&mut self) -> Result<String, ParseError> {
        let mut key = self.cur.value.clone(); self.eat(TokenType::Identifier)?;
        while self.cur.typ == TokenType::Dot {
            self.eat(TokenType::Dot)?;
            if self.cur.typ != TokenType::Identifier { return Err(self.err("expected identifier after dot")); }
            key.push('.'); key.push_str(&self.cur.value); self.eat(TokenType::Identifier)?;
        }
        Ok(key)
    }

    fn parse_value(&mut self) -> Result<AstNode, ParseError> {
        match self.cur.typ {
            TokenType::String => { let v = self.cur.value.clone(); self.eat(TokenType::String)?; Ok(AstNode::String { kind: "string", value: v }) }
            TokenType::Number => {
                let v: f64 = self.cur.value.parse().map_err(|_| self.err("invalid number"))?;
                self.eat(TokenType::Number)?;
                Ok(AstNode::Number { kind: "number", value: v })
            }
            TokenType::Identifier => {
                let v = self.cur.value.clone(); self.eat(TokenType::Identifier)?;
                if v == "true" { Ok(AstNode::Boolean { kind: "boolean", value: true }) }
                else if v == "false" { Ok(AstNode::Boolean { kind: "boolean", value: false }) }
                else { Err(self.err("invalid bare value")) }
            }
            TokenType::LBracket => self.parse_array(),
            _ => Err(self.err("unexpected value")),
        }
    }

    fn parse_array(&mut self) -> Result<AstNode, ParseError> {
        self.eat(TokenType::LBracket)?;
        let mut elements = Vec::new();
        if self.cur.typ != TokenType::RBracket {
            elements.push(self.parse_value()?);
            while self.cur.typ == TokenType::Comma {
                self.eat(TokenType::Comma)?;
                if self.cur.typ == TokenType::RBracket { return Err(self.err("trailing comma in array")); }
                elements.push(self.parse_value()?);
            }
        }
        self.eat(TokenType::RBracket)?;
        Ok(AstNode::Array { kind: "array", elements })
    }

    fn eat(&mut self, typ: TokenType) -> Result<(), ParseError> {
        if self.cur.typ != typ { return Err(self.err("unexpected token")); }
        self.cur = self.lex.next_token()?;
        Ok(())
    }

    fn peek_token(&mut self) -> Result<Token, ParseError> {
        let st = self.lex.snapshot();
        let tok = self.lex.next_token()?;
        self.lex.restore(st);
        Ok(tok)
    }

    fn err(&self, m: &str) -> ParseError { ParseError::new(m, self.cur.line, self.cur.col) }

    fn ensure_key_valid(&self, key: &str, seen: &[String]) -> Result<(), ParseError> {
        if seen.iter().any(|k| k == key) { return Err(self.err("duplicate key")); }
        let parts: Vec<&str> = key.split('.').collect();
        for existing in seen {
            let ex: Vec<&str> = existing.split('.').collect();
            if is_prefix(&parts, &ex) || is_prefix(&ex, &parts) { return Err(self.err("key conflict")); }
        }
        Ok(())
    }
}

fn is_prefix(left: &[&str], right: &[&str]) -> bool {
    if left.len() >= right.len() { return false; }
    left.iter().enumerate().all(|(i, v)| right[i] == *v)
}
