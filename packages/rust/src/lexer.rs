use crate::error::ParseError;

#[derive(Copy, Clone, Debug, PartialEq)]
pub enum TokenType { Identifier, String, Number, Equal, Comma, Dot, Do, End, LBracket, RBracket, Eof }

#[derive(Clone, Debug)]
pub struct Token { pub typ: TokenType, pub value: String, pub line: usize, pub col: usize }

#[derive(Clone)]
pub struct Lexer { input: Vec<char>, pos: usize, line: usize, col: usize }

impl Lexer {
    pub fn new(s: &str) -> Self { Self { input: s.chars().collect(), pos: 0, line: 1, col: 1 } }
    pub fn snapshot(&self) -> (usize, usize, usize) { (self.pos, self.line, self.col) }
    pub fn restore(&mut self, st: (usize, usize, usize)) { (self.pos, self.line, self.col) = st; }

    pub fn next_token(&mut self) -> Result<Token, ParseError> {
        self.skip();
        if self.eof() { return Ok(Token { typ: TokenType::Eof, value: String::new(), line: self.line, col: self.col }); }
        let (line, col, ch) = (self.line, self.col, self.cur());
        let one = |typ, v| Token { typ, value: v, line, col };
        match ch {
            '=' => { self.adv(); Ok(one(TokenType::Equal, "=".into())) }
            ',' => { self.adv(); Ok(one(TokenType::Comma, ",".into())) }
            '.' => { self.adv(); Ok(one(TokenType::Dot, ".".into())) }
            '[' => { self.adv(); Ok(one(TokenType::LBracket, "[".into())) }
            ']' => { self.adv(); Ok(one(TokenType::RBracket, "]".into())) }
            '"' => self.read_string(line, col),
            '-' if self.peek().is_ascii_digit() => Ok(self.read_number(line, col)),
            c if c.is_ascii_digit() => Ok(self.read_number(line, col)),
            c if c.is_ascii_alphabetic() || c == '_' => Ok(self.read_ident(line, col)),
            _ => Err(ParseError::new("unexpected character", line, col)),
        }
    }

    fn read_string(&mut self, line: usize, col: usize) -> Result<Token, ParseError> {
        self.adv();
        let mut out = String::new();
        while !self.eof() && self.cur() != '"' {
            if self.cur() == '\\' {
                self.adv();
                if self.eof() { return Err(ParseError::new("unterminated escape", line, col)); }
                out.push(match self.cur() {
                    '"' => '"', 'n' => '\n', 't' => '\t', '\\' => '\\',
                    _ => return Err(ParseError::new("invalid escape", self.line, self.col)),
                });
                self.adv();
            } else { out.push(self.cur()); self.adv(); }
        }
        if self.eof() { return Err(ParseError::new("unterminated string", line, col)); }
        self.adv();
        Ok(Token { typ: TokenType::String, value: out, line, col })
    }

    fn read_number(&mut self, line: usize, col: usize) -> Token {
        let mut out = String::new();
        if self.cur() == '-' { out.push('-'); self.adv(); }
        while !self.eof() && self.cur().is_ascii_digit() { out.push(self.cur()); self.adv(); }
        if !self.eof() && self.cur() == '.' && self.peek().is_ascii_digit() {
            out.push('.'); self.adv();
            while !self.eof() && self.cur().is_ascii_digit() { out.push(self.cur()); self.adv(); }
        }
        Token { typ: TokenType::Number, value: out, line, col }
    }

    fn read_ident(&mut self, line: usize, col: usize) -> Token {
        let mut out = String::new();
        while !self.eof() && (self.cur().is_ascii_alphanumeric() || self.cur() == '_') { out.push(self.cur()); self.adv(); }
        let typ = if out == "do" { TokenType::Do } else if out == "end" { TokenType::End } else { TokenType::Identifier };
        Token { typ, value: out, line, col }
    }

    fn skip(&mut self) {
        while !self.eof() {
            if self.cur().is_whitespace() { self.adv(); }
            else if self.cur() == '#' { while !self.eof() && self.cur() != '\n' { self.adv() } }
            else { break; }
        }
    }

    fn adv(&mut self) { if self.eof() { return; } if self.cur() == '\n' { self.line += 1; self.col = 1 } else { self.col += 1 } self.pos += 1; }
    fn cur(&self) -> char { self.input[self.pos] }
    fn peek(&self) -> char { self.input.get(self.pos + 1).copied().unwrap_or('\0') }
    fn eof(&self) -> bool { self.pos >= self.input.len() }
}
