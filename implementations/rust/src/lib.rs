pub mod ast;
pub mod core;
pub mod convert;
pub mod error;
pub mod formatter;
mod lexer;
mod parser;

pub use error::ParseError;
pub use formatter::format;
pub use convert::{to_hcl, to_object, to_toml, to_yaml};

pub fn parse(text: &str) -> Result<ast::DocumentNode, ParseError> {
    core::parse(text)
}
