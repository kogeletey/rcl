module rcl.ast;

enum NodeKind { str, num, boolv, arr }

struct AstNode {
  NodeKind kind;
  string sval;
  double nval;
  bool bval;
  bool isInt;
  AstNode[] elems;
}

struct BlockNode {
  string name;
  bool hasArg;
  string arg;
  string[] propOrder;
  AstNode[string] props;
  BlockNode[] blocks;
  BlockNode[] named;
}

struct Document {
  BlockNode[] blocks;
}
