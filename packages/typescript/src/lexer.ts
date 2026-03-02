import { ParserException } from "./error.js";
import { Token, TokenType } from "./token.js";

type LexerState = { pos: number; line: number; column: number };

export class Lexer {
  private pos = 0;
  private line = 1;
  private column = 1;

  constructor(private readonly input: string) {}

  snapshot(): LexerState {
    return { pos: this.pos, line: this.line, column: this.column };
  }

  restore(state: LexerState): void {
    this.pos = state.pos;
    this.line = state.line;
    this.column = state.column;
  }

  nextToken(): Token {
    this.skipWhitespaceAndComments();
    if (this.eof()) return this.mk(TokenType.EOF, "", this.line, this.column);

    const line = this.line;
    const col = this.column;
    const ch = this.current();

    if (ch === "=") return this.single(TokenType.Equal, "=", line, col);
    if (ch === ",") return this.single(TokenType.Comma, ",", line, col);
    if (ch === ".") return this.single(TokenType.Dot, ".", line, col);
    if (ch === "[") return this.single(TokenType.LBracket, "[", line, col);
    if (ch === "]") return this.single(TokenType.RBracket, "]", line, col);
    if (ch === '"') return this.readString(line, col);
    if (this.isNumberStart(ch)) return this.readNumber(line, col);
    if (this.isIdentStart(ch)) return this.readIdent(line, col);

    throw new ParserException(`unexpected character '${ch}'`, line, col);
  }

  private readString(line: number, col: number): Token {
    this.advance();
    let out = "";
    while (!this.eof() && this.current() !== '"') {
      if (this.current() === "\\") {
        this.advance();
        if (this.eof()) throw new ParserException("unterminated escape sequence", line, col);
        const esc = this.current();
        if (esc === '"') out += '"';
        else if (esc === "n") out += "\n";
        else if (esc === "t") out += "\t";
        else if (esc === "\\") out += "\\";
        else throw new ParserException(`invalid escape \\${esc}`, this.line, this.column);
        this.advance();
      } else {
        out += this.current();
        this.advance();
      }
    }
    if (this.eof()) throw new ParserException("unterminated string", line, col);
    this.advance();
    return this.mk(TokenType.String, out, line, col);
  }

  private readNumber(line: number, col: number): Token {
    let out = "";
    if (this.current() === "-") {
      out += "-";
      this.advance();
    }
    while (!this.eof() && /[0-9]/.test(this.current())) {
      out += this.current();
      this.advance();
    }
    if (!this.eof() && this.current() === "." && /[0-9]/.test(this.peek() ?? "")) {
      out += ".";
      this.advance();
      while (!this.eof() && /[0-9]/.test(this.current())) {
        out += this.current();
        this.advance();
      }
    }
    return this.mk(TokenType.Number, out, line, col);
  }

  private readIdent(line: number, col: number): Token {
    let out = "";
    while (!this.eof() && this.isIdentPart(this.current())) {
      out += this.current();
      this.advance();
    }
    if (out === "do") return this.mk(TokenType.Do, out, line, col);
    if (out === "end") return this.mk(TokenType.End, out, line, col);
    return this.mk(TokenType.Identifier, out, line, col);
  }

  private skipWhitespaceAndComments(): void {
    while (!this.eof()) {
      const ch = this.current();
      if (/\s/.test(ch)) this.advance();
      else if (ch === "#") this.skipToEol(); else break;
    }
  }

  private skipToEol(): void {
    while (!this.eof() && this.current() !== "\n") this.advance();
  }

  private single(type: TokenType, value: string, line: number, col: number): Token {
    this.advance();
    return this.mk(type, value, line, col);
  }

  private mk(type: TokenType, value: string, line: number, column: number): Token {
    return { type, value, line, column };
  }

  private isIdentStart(ch: string): boolean { return /[A-Za-z_]/.test(ch); }
  private isIdentPart(ch: string): boolean { return /[A-Za-z0-9_]/.test(ch); }
  private isNumberStart(ch: string): boolean {
    return /[0-9]/.test(ch) || (ch === "-" && /[0-9]/.test(this.peek() ?? ""));
  }

  private advance(): void {
    if (this.eof()) return;
    if (this.current() === "\n") { this.line += 1; this.column = 1; }
    else this.column += 1;
    this.pos += 1;
  }
  private current(): string { return this.input[this.pos] ?? ""; }
  private peek(): string | undefined { return this.input[this.pos + 1]; }
  private eof(): boolean { return this.pos >= this.input.length; }
}
