import { DocumentNode } from "./ast.js";
import { Lexer } from "./lexer.js";
import { Parser } from "./parser.js";
import { toObject } from "./convert.js";

export * from "./ast.js";

export function parse(text: string): DocumentNode {
  return new Parser(new Lexer(text)).parse();
}

export { toObject };
