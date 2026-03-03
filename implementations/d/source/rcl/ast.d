module rcl.ast;

struct BlockNode;

enum NodeKind { str, num, boolv, arr, block }

struct AstNode {
  NodeKind kind;
  string sval;
  double nval;
  bool bval;
  bool isInt;
  AstNode[] elems;
  BlockNode* blockVal;
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
  bool hasRootValue;
  AstNode rootValue;
}
