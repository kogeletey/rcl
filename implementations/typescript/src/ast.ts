export type NumberValue = number;

export interface ParseError {
  message: string;
  line: number;
  column: number;
}

export interface BaseNode {
  kind: string;
}

export interface StringNode extends BaseNode {
  kind: "string";
  value: string;
}

export interface NumberNode extends BaseNode {
  kind: "number";
  value: NumberValue;
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
