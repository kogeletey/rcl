import { AstNode, BlockNode, DocumentNode } from "./ast.js";
import { ParserException } from "./error.js";
import { Lexer } from "./lexer.js";
import { Token, TokenType } from "./token.js";

export class Parser {
  private current: Token;

  constructor(private readonly lexer: Lexer) {
    this.current = lexer.nextToken();
  }

  parse(): DocumentNode {
    const blocks: BlockNode[] = [];
    while (this.current.type !== TokenType.EOF) blocks.push(this.parseBlock());
    return { kind: "document", blocks };
  }

  private parseBlock(): BlockNode {
    const name = this.current.value;
    this.eat(TokenType.Identifier);

    let argument: string | undefined;
    if (this.current.type === TokenType.String) {
      argument = this.current.value;
      this.eat(TokenType.String);
    }

    this.eat(TokenType.Do);

    const properties: Record<string, AstNode> = {};
    const blocks: Record<string, BlockNode> = {};
    const namedBlocks: BlockNode[] = [];

    while (this.current.type !== TokenType.End) {
      if (this.current.type === TokenType.EOF) throw this.err("missing 'end' for block");
      if (this.current.type !== TokenType.Identifier) throw this.err(`expected identifier, got ${this.current.type}`);

      const next = this.peekToken();
      if (next.type === TokenType.Do || next.type === TokenType.String) {
        const child = this.parseBlock();
        if (child.argument) {
          namedBlocks.push(child);
          blocks[`${child.name}:${child.argument}`] = child;
        } else blocks[child.name] = child;
      } else if (next.type === TokenType.Equal || next.type === TokenType.Dot) {
        const key = this.parsePropertyKey();
        this.eat(TokenType.Equal);
        properties[key] = this.parseValue();
      } else throw this.err(`invalid statement after '${this.current.value}'`);
    }

    this.eat(TokenType.End);
    const block: BlockNode = { kind: "block", name, properties, blocks };
    if (argument !== undefined) block.argument = argument;
    if (namedBlocks.length > 0) block.named_blocks = namedBlocks;
    return block;
  }

  private parsePropertyKey(): string {
    let key = this.current.value;
    this.eat(TokenType.Identifier);
    while (this.current.type === TokenType.Dot) {
      this.eat(TokenType.Dot);
      if (this.current.type !== TokenType.Identifier) throw this.err("expected identifier after dot");
      key += `.${this.current.value}`;
      this.eat(TokenType.Identifier);
    }
    return key;
  }

  private parseValue(): AstNode {
    if (this.current.type === TokenType.String) {
      const v = this.current.value; this.eat(TokenType.String); return { kind: "string", value: v };
    }
    if (this.current.type === TokenType.Number) {
      const v = Number(this.current.value); this.eat(TokenType.Number); return { kind: "number", value: v };
    }
    if (this.current.type === TokenType.Identifier) {
      const v = this.current.value; this.eat(TokenType.Identifier);
      if (v === "true") return { kind: "boolean", value: true };
      if (v === "false") return { kind: "boolean", value: false };
      return { kind: "string", value: v };
    }
    if (this.current.type === TokenType.LBracket) return this.parseArray();
    throw this.err(`unexpected token ${this.current.type}`);
  }

  private parseArray(): AstNode {
    this.eat(TokenType.LBracket);
    const elements: AstNode[] = [];
    if (this.current.type !== TokenType.RBracket) {
      elements.push(this.parseValue());
      while (this.current.type === TokenType.Comma) {
        this.eat(TokenType.Comma);
        elements.push(this.parseValue());
      }
    }
    this.eat(TokenType.RBracket);
    return { kind: "array", elements };
  }

  private eat(type: TokenType): void {
    if (this.current.type !== type) throw this.err(`expected ${type}, got ${this.current.type}`);
    this.current = this.lexer.nextToken();
  }

  private peekToken(): Token {
    const st = this.lexer.snapshot();
    const tok = this.lexer.nextToken();
    this.lexer.restore(st);
    return tok;
  }

  private err(message: string): ParserException {
    return new ParserException(message, this.current.line, this.current.column);
  }
}
