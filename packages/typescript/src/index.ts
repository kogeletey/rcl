export type AstValue = string | number | boolean | AstNode[] | Record<string, AstNode>;

export interface BaseNode {
  kind: string;
}

export interface StringNode extends BaseNode {
  kind: "string";
  value: string;
}

export interface NumberNode extends BaseNode {
  kind: "number";
  value: number;
}

export interface BooleanNode extends BaseNode {
  kind: "boolean";
  value: boolean;
}

export interface ArrayNode extends BaseNode {
  kind: "array";
  elements: AstNode[];
}

export interface BlockNode extends BaseNode {
  kind: "block";
  name: string;
  argument?: string;
  properties: Record<string, AstNode>;
  blocks: Record<string, BlockNode>;
  named_blocks?: BlockNode[];
}

export interface DocumentNode extends BaseNode {
  kind: "document";
  blocks: BlockNode[];
}

export type AstNode = StringNode | NumberNode | BooleanNode | ArrayNode | BlockNode | DocumentNode;

class Parser {
  private i = 0;

  constructor(private readonly text: string) {}

  parse(): DocumentNode {
    return { kind: "document", blocks: this.parseBlocks() };
  }

  private parseBlocks(untilWord?: string): BlockNode[] {
    const blocks: BlockNode[] = [];
    while (true) {
      this.skipSpace();
      if (this.eof()) break;
      if (untilWord && this.peekWord() === untilWord) {
        this.readWord();
        break;
      }
      blocks.push(this.parseBlock());
    }
    return blocks;
  }

  private parseBlock(): BlockNode {
    const name = this.readWord();
    this.skipSpace();
    let argument: string | undefined;
    if (this.current() === '"') argument = this.readString();
    this.expectWord("do");

    const properties: Record<string, AstNode> = {};
    const blocks: Record<string, BlockNode> = {};
    const namedBlocks: BlockNode[] = [];

    while (true) {
      this.skipSpace();
      if (this.peekWord() === "end") break;

      let key = this.readWord();
      this.skipSpace();
      if (this.peekWord() === "do" || this.current() === '"') {
        let childArg: string | undefined;
        if (this.current() === '"') childArg = this.readString();
        this.expectWord("do");
        const child = this.parseBlockBody(key, childArg);
        if (childArg) {
          namedBlocks.push(child);
          blocks[`${key}:${childArg}`] = child;
        } else {
          blocks[key] = child;
        }
      } else {
        while (this.current() === ".") {
          this.advance();
          key += `.${this.readWord()}`;
          this.skipSpace();
        }
        this.expect("=");
        properties[key] = this.parseValue();
      }
    }

    this.expectWord("end");
    const block: BlockNode = { kind: "block", name, properties, blocks };
    if (argument) block.argument = argument;
    if (namedBlocks.length > 0) block.named_blocks = namedBlocks;
    return block;
  }

  private parseBlockBody(name: string, argument?: string): BlockNode {
    const properties: Record<string, AstNode> = {};
    const blocks: Record<string, BlockNode> = {};
    const namedBlocks: BlockNode[] = [];

    while (true) {
      this.skipSpace();
      if (this.peekWord() === "end") break;

      let key = this.readWord();
      this.skipSpace();
      if (this.peekWord() === "do" || this.current() === '"') {
        let childArg: string | undefined;
        if (this.current() === '"') childArg = this.readString();
        this.expectWord("do");
        const child = this.parseBlockBody(key, childArg);
        if (childArg) {
          namedBlocks.push(child);
          blocks[`${key}:${childArg}`] = child;
        } else {
          blocks[key] = child;
        }
      } else {
        while (this.current() === ".") {
          this.advance();
          key += `.${this.readWord()}`;
          this.skipSpace();
        }
        this.expect("=");
        properties[key] = this.parseValue();
      }
    }

    this.expectWord("end");
    const block: BlockNode = { kind: "block", name, properties, blocks };
    if (argument) block.argument = argument;
    if (namedBlocks.length > 0) block.named_blocks = namedBlocks;
    return block;
  }

  private parseValue(): AstNode {
    this.skipSpace();
    if (this.current() === '"') {
      return { kind: "string", value: this.readString() };
    }
    if (this.current() === "[") {
      return this.parseArray();
    }
    const token = this.readToken();
    if (token === "true" || token === "false") {
      return { kind: "boolean", value: token === "true" };
    }
    if (/^-?\d+(?:\.\d+)?$/.test(token)) {
      return { kind: "number", value: Number(token) };
    }
    return { kind: "string", value: token };
  }

  private parseArray(): ArrayNode {
    this.expect("[");
    const elements: AstNode[] = [];
    while (true) {
      this.skipSpace();
      if (this.current() === "]") break;
      elements.push(this.parseValue());
      this.skipSpace();
      if (this.current() === "]") break;
      this.expect(",");
    }
    this.expect("]");
    return { kind: "array", elements };
  }

  private readString(): string {
    this.expect('"');
    let out = "";
    while (!this.eof() && this.current() !== '"') {
      if (this.current() === "\\") {
        this.advance();
        const ch = this.current();
        if (ch === "n") out += "\n";
        else if (ch === "t") out += "\t";
        else out += ch;
      } else {
        out += this.current();
      }
      this.advance();
    }
    this.expect('"');
    return out;
  }

  private readWord(): string {
    this.skipSpace();
    let out = "";
    while (!this.eof() && /[A-Za-z0-9_]/.test(this.current())) {
      out += this.current();
      this.advance();
    }
    return out;
  }

  private readToken(): string {
    this.skipSpace();
    let out = "";
    while (!this.eof() && !/[\s,\]]/.test(this.current())) {
      out += this.current();
      this.advance();
    }
    return out;
  }

  private peekWord(): string {
    let j = this.i;
    while (j < this.text.length && /\s/.test(this.text[j])) j += 1;
    let out = "";
    while (j < this.text.length && /[A-Za-z0-9_]/.test(this.text[j])) {
      out += this.text[j];
      j += 1;
    }
    return out;
  }

  private skipSpace(): void {
    while (!this.eof()) {
      if (/\s/.test(this.current())) {
        this.advance();
      } else if (this.current() === "#") {
        while (!this.eof() && this.current() !== "\n") this.advance();
      } else {
        break;
      }
    }
  }

  private expect(ch: string): void {
    this.skipSpace();
    if (this.current() !== ch) throw new Error(`expected ${ch}`);
    this.advance();
  }

  private expectWord(word: string): void {
    const got = this.readWord();
    if (got !== word) throw new Error(`expected ${word}, got ${got}`);
  }

  private current(): string {
    return this.text[this.i] ?? "";
  }

  private advance(): void {
    this.i += 1;
  }

  private eof(): boolean {
    return this.i >= this.text.length;
  }
}

export function parse(text: string): DocumentNode {
  return new Parser(text).parse();
}

function formatValue(node: AstNode): string {
  switch (node.kind) {
    case "string":
      return `"${node.value.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n").replace(/\t/g, "\\t")}"`;
    case "number":
      return `${node.value}`;
    case "boolean":
      return node.value ? "true" : "false";
    case "array":
      return `[${node.elements.map(formatValue).join(", ")}]`;
    default:
      throw new Error(`unsupported value node kind: ${node.kind}`);
  }
}

function formatBlock(block: BlockNode, indent = 0): string {
  const pad = "  ".repeat(indent);
  const header = block.argument
    ? `${pad}${block.name} "${block.argument}" do`
    : `${pad}${block.name} do`;
  const lines: string[] = [header];

  for (const [key, value] of Object.entries(block.properties)) {
    lines.push(`${pad}  ${key} = ${formatValue(value)}`);
  }

  for (const child of Object.values(block.blocks)) {
    lines.push(formatBlock(child, indent + 1));
  }

  lines.push(`${pad}end`);
  return lines.join("\n");
}

export function format(document: DocumentNode): string {
  return document.blocks.map((block) => formatBlock(block)).join("\n\n");
}
