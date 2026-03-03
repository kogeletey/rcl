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
    if (this.current.type === TokenType.Do) {
      this.eat(TokenType.Do);
      const rootValue = this.parseArray();
      if (this.current.type !== TokenType.EOF) throw this.err("unexpected token after root array");
      return { kind: "document", blocks: [], root_value: rootValue };
    }

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

    const { properties, blocks, namedBlocks } = this.parseBlockBody();

    this.eat(TokenType.End);
    const block: BlockNode = { kind: "block", name, properties, blocks };
    if (argument !== undefined) block.argument = argument;
    if (namedBlocks.length > 0) block.named_blocks = namedBlocks;
    return block;
  }

  private parseAnonymousBlock(): BlockNode {
    this.eat(TokenType.Do);
    const { properties, blocks, namedBlocks } = this.parseBlockBody();
    this.eat(TokenType.End);
    const block: BlockNode = { kind: "block", name: "", properties, blocks };
    if (namedBlocks.length > 0) block.named_blocks = namedBlocks;
    return block;
  }

  private parseBlockBody(): { properties: Record<string, AstNode>; blocks: Record<string, BlockNode>; namedBlocks: BlockNode[] } {
    const properties: Record<string, AstNode> = {};
    const blocks: Record<string, BlockNode> = {};
    const namedBlocks: BlockNode[] = [];
    const seenKeys = new Set<string>();

    while (this.current.type !== TokenType.End) {
      if (this.current.type === TokenType.EOF) throw this.err("missing 'end' for block");
      if (this.current.type !== TokenType.Identifier) throw this.err(`expected identifier, got ${this.current.type}`);

      const next = this.peekToken();
      if (next.type === TokenType.Do) {
        const afterDo = this.peekToken(2);
        if (afterDo.type === TokenType.LBracket) {
          const key = this.current.value;
          this.eat(TokenType.Identifier);
          this.ensurePropertyKeyValid(key, seenKeys);
          this.eat(TokenType.Do);
          properties[key] = this.parseArray();
          this.eat(TokenType.End);
        } else {
          const child = this.parseBlock();
          if (child.argument) namedBlocks.push(child);
          else blocks[child.name] = child;
        }
      } else if (next.type === TokenType.String) {
        const child = this.parseBlock();
        if (child.argument) namedBlocks.push(child);
        else blocks[child.name] = child;
      } else if (next.type === TokenType.Equal || next.type === TokenType.Dot) {
        const key = this.parsePropertyKey();
        this.ensurePropertyKeyValid(key, seenKeys);
        this.eat(TokenType.Equal);
        properties[key] = this.parseValue();
      } else throw this.err(`invalid statement after '${this.current.value}'`);
    }

    return { properties, blocks, namedBlocks };
  }

  private parsePropertyKey(): string {
    let key = this.current.value;
    this.eat(TokenType.Identifier);
    for (;;) {
      const curType = this.current.type;
      if (curType !== TokenType.Dot) break;
      this.eat(TokenType.Dot);
      const afterDot = this.current.type;
      if (afterDot !== TokenType.Identifier) throw this.err("expected identifier after dot");
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
      throw this.err(`invalid bare value '${v}'`);
    }
    if (this.current.type === TokenType.LBracket) return this.parseArray();
    if (this.current.type === TokenType.Do) return this.parseAnonymousBlock();
    throw this.err(`unexpected token ${this.current.type}`);
  }

  private parseArray(): AstNode {
    this.eat(TokenType.LBracket);
    const elements: AstNode[] = [];
    if (this.current.type !== TokenType.RBracket) {
      elements.push(this.parseValue());
      for (;;) {
        const curType = this.current.type;
        if (curType !== TokenType.Comma) break;
        const nextType = this.peekToken().type;
        if (nextType === TokenType.RBracket) throw this.err("trailing comma in array");
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

  private peekToken(offset = 1): Token {
    const st = this.lexer.snapshot();
    let tok = this.current;
    for (let i = 0; i < offset; i += 1) tok = this.lexer.nextToken();
    this.lexer.restore(st);
    return tok;
  }

  private err(message: string): ParserException {
    return new ParserException(message, this.current.line, this.current.column);
  }

  private ensurePropertyKeyValid(key: string, seen: Set<string>): void {
    if (seen.has(key)) throw this.err(`duplicate key '${key}'`);
    const parts = key.split(".");
    for (const existing of seen) {
      const ex = existing.split(".");
      if (this.isPrefix(parts, ex) || this.isPrefix(ex, parts)) throw this.err(`key conflict '${key}' vs '${existing}'`);
    }
    seen.add(key);
  }

  private isPrefix(left: string[], right: string[]): boolean {
    if (left.length >= right.length) return false;
    for (let i = 0; i < left.length; i += 1) if (left[i] !== right[i]) return false;
    return true;
  }
}
