pub mod ast;
pub mod error;
pub mod formatter;
mod lexer;
mod parser;

pub use error::ParseError;
pub use formatter::format;

pub fn parse(text: &str) -> Result<ast::DocumentNode, ParseError> {
    parser::Parser::new(text)?.parse()
}
