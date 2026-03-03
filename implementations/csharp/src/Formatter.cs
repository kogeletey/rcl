using System.Text;
using System.Collections.Generic;

namespace RCLImpl {
public static class Formatter {
  public static string Format(DocumentNode d){
    if(d.RootValue is ArrayNode) return "do "+FmtVal(d.RootValue);
    var o=new StringBuilder(); foreach(var b in d.Blocks) FmtBlock(o,b,0); return o.ToString();
  }

  static void FmtBlock(StringBuilder o, BlockNode b, int n){
    var pad=new string(' ',n*2); o.Append(pad).Append(b.Name); if(b.Argument!=null) o.Append(' ').Append(Q(b.Argument)); o.Append(" do\n");
    foreach(var k in b.PropertyOrder){
      if(b.Properties[k] is ArrayNode) o.Append(pad).Append("  ").Append(k).Append(" do ").Append(FmtVal(b.Properties[k])).Append(" end\n");
      else o.Append(pad).Append("  ").Append(k).Append(" = ").Append(FmtVal(b.Properties[k])).Append('\n');
    }
    foreach(var c in b.Blocks) FmtBlock(o,c,n+1);
    foreach(var c in b.NamedBlocks) FmtBlock(o,c,n+1);
    o.Append(pad).Append("end\n");
  }

  static string FmtVal(IAstNode n){
    if(n is StringNode) return Q(((StringNode)n).Value);
    if(n is NumberNode) return ((NumberNode)n).Value.ToString(System.Globalization.CultureInfo.InvariantCulture);
    if(n is BooleanNode) return ((BooleanNode)n).Value?"true":"false";
    if(n is BlockNode) return FmtAnon((BlockNode)n);
    var a=(ArrayNode)n; var o="[";
    for(int i=0;i<a.Elements.Count;i++){ if(i>0) o+=", "; o+=FmtVal(a.Elements[i]); }
    return o+"]";
  }

  static string FmtAnon(BlockNode b){
    var parts=new List<string>();
    foreach(var k in b.PropertyOrder) parts.Add(k+" = "+FmtVal(b.Properties[k]));
    foreach(var c in b.Blocks) parts.Add(FmtInline(c));
    foreach(var c in b.NamedBlocks) parts.Add(FmtInline(c));
    if(parts.Count==0) return "do end";
    return "do "+string.Join(" ",parts)+" end";
  }

  static string FmtInline(BlockNode b){
    var head=b.Name+" do";
    if(b.Argument!=null) head=b.Name+" "+Q(b.Argument)+" do";
    var parts=new List<string>();
    foreach(var k in b.PropertyOrder) parts.Add(k+" = "+FmtVal(b.Properties[k]));
    foreach(var c in b.Blocks) parts.Add(FmtInline(c));
    foreach(var c in b.NamedBlocks) parts.Add(FmtInline(c));
    if(parts.Count==0) return head+" end";
    return head+" "+string.Join(" ",parts)+" end";
  }

  static string Q(string s){ return "\""+s.Replace("\\","\\\\").Replace("\"","\\\"").Replace("\n","\\n").Replace("\t","\\t")+"\""; }
}
}
