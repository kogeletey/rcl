export enum TokenType {
  Identifier = "Identifier",
  String = "String",
  Number = "Number",
  Equal = "Equal",
  Comma = "Comma",
  Dot = "Dot",
  Do = "Do",
  End = "End",
  LBracket = "LBracket",
  RBracket = "RBracket",
  EOF = "EOF",
}

export interface Token {
  type: TokenType;
  value: string;
  line: number;
  column: number;
}
