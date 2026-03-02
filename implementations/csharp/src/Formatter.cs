using System.Text;

namespace RCLImpl {
public static class Formatter {
  public static string Format(DocumentNode d){ var o=new StringBuilder(); foreach(var b in d.Blocks) FmtBlock(o,b,0); return o.ToString(); }

  static void FmtBlock(StringBuilder o, BlockNode b, int n){
    var pad=new string(' ',n*2); o.Append(pad).Append(b.Name); if(b.Argument!=null) o.Append(' ').Append(Q(b.Argument)); o.Append(" do\n");
    foreach(var k in b.PropertyOrder) o.Append(pad).Append("  ").Append(k).Append(" = ").Append(FmtVal(b.Properties[k])).Append('\n');
    foreach(var c in b.Blocks) FmtBlock(o,c,n+1);
    foreach(var c in b.NamedBlocks) FmtBlock(o,c,n+1);
    o.Append(pad).Append("end\n");
  }

  static string FmtVal(IAstNode n){
    if(n is StringNode) return Q(((StringNode)n).Value);
    if(n is NumberNode) return ((NumberNode)n).Value.ToString(System.Globalization.CultureInfo.InvariantCulture);
    if(n is BooleanNode) return ((BooleanNode)n).Value?"true":"false";
    var a=(ArrayNode)n; var o="[";
    for(int i=0;i<a.Elements.Count;i++){ if(i>0) o+=", "; o+=FmtVal(a.Elements[i]); }
    return o+"]";
  }

  static string Q(string s){ return "\""+s.Replace("\\","\\\\").Replace("\"","\\\"").Replace("\n","\\n").Replace("\t","\\t")+"\""; }
}
}
