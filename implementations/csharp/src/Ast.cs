using System.Collections.Generic;

namespace RCLImpl {
public interface IAstNode { string Kind { get; } }

public sealed class StringNode : IAstNode { public string Kind { get { return "string"; } } public string Value; public StringNode(string v){ Value=v; } }
public sealed class NumberNode : IAstNode { public string Kind { get { return "number"; } } public double Value; public NumberNode(double v){ Value=v; } }
public sealed class BooleanNode : IAstNode { public string Kind { get { return "boolean"; } } public bool Value; public BooleanNode(bool v){ Value=v; } }
public sealed class ArrayNode : IAstNode { public string Kind { get { return "array"; } } public List<IAstNode> Elements = new List<IAstNode>(); }

public sealed class BlockNode : IAstNode {
  public string Kind { get { return "block"; } }
  public string Name;
  public string Argument;
  public Dictionary<string, IAstNode> Properties = new Dictionary<string, IAstNode>();
  public List<string> PropertyOrder = new List<string>();
  public List<BlockNode> Blocks = new List<BlockNode>();
  public List<BlockNode> NamedBlocks = new List<BlockNode>();
  public BlockNode(string n, string a){ Name=n; Argument=a; }
}

public sealed class DocumentNode : IAstNode {
  public string Kind { get { return "document"; } }
  public List<BlockNode> Blocks = new List<BlockNode>();
  public IAstNode RootValue;
}
}
