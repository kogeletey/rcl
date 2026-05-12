pub use crate::ast;
pub use crate::convert::{to_object, Value};
pub use crate::error::ParseError;

pub fn parse(text: &str) -> Result<ast::DocumentNode, ParseError> {
    crate::parser::Parser::new(text)?.parse()
}
