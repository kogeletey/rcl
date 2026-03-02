using System.Collections;
using System.Collections.Generic;
using System.Text;

namespace RCLImpl {
public static class Converters {
  public static Dictionary<string, object> ToObject(DocumentNode d){
    var outp=new Dictionary<string, object>();
    foreach(var b in d.Blocks){
      if(b.Argument==null) outp[b.Name]=BlockObj(b);
      else { var m=new Dictionary<string, object>(); m[b.Argument]=BlockObj(b); outp[Base(b.Name)]=m; }
    }
    return outp;
  }

  static Dictionary<string, object> BlockObj(BlockNode b){
    var outp=new Dictionary<string, object>();
    foreach(var k in b.PropertyOrder) PutPath(outp,k,Val(b.Properties[k]));
    foreach(var c in b.Blocks) MergeAt(outp,c.Name,BlockObj(c));
    foreach(var c in b.NamedBlocks){ var bn=Base(c.Name); var m=outp.ContainsKey(bn)?(Dictionary<string, object>)outp[bn]:new Dictionary<string, object>(); m[c.Argument]=BlockObj(c); outp[bn]=m; }
    return outp;
  }

  static void PutPath(Dictionary<string, object> o,string k,object v){
    var p=k.Split('.'); var cur=o;
    for(int i=0;i<p.Length-1;i++){ if(!cur.ContainsKey(p[i])) cur[p[i]]=new Dictionary<string, object>(); cur=(Dictionary<string, object>)cur[p[i]]; }
    cur[p[p.Length-1]]=v;
  }

  static void MergeAt(Dictionary<string, object> o,string k,Dictionary<string, object> v){
    var m=o.ContainsKey(k)?(Dictionary<string, object>)o[k]:new Dictionary<string, object>();
    foreach(var it in v) m[it.Key]=it.Value; o[k]=m;
  }

  static object Val(IAstNode n){
    if(n is StringNode) return ((StringNode)n).Value;
    if(n is NumberNode) return ((NumberNode)n).Value;
    if(n is BooleanNode) return ((BooleanNode)n).Value;
    var a=new List<object>(); foreach(var x in ((ArrayNode)n).Elements) a.Add(Val(x)); return a;
  }

  static string Base(string s){ return s.EndsWith("s")?s:s+"s"; }

  public static string ToYAML(DocumentNode d){ return Yaml(ToObject(d),0); }
  public static string ToTOML(DocumentNode d){ var o=new StringBuilder(); Toml(o,ToObject(d),""); return o.ToString(); }
  public static string ToHCL(DocumentNode d){ return Hcl(ToObject(d),0); }

  static string Yaml(Dictionary<string, object> m,int n){
    var o=new StringBuilder();
    foreach(var it in m){ var pad=new string(' ',n*2); if(it.Value is Dictionary<string, object>) o.Append(pad).Append(it.Key).Append(":\n").Append(Yaml((Dictionary<string, object>)it.Value,n+1)); else o.Append(pad).Append(it.Key).Append(": ").Append(Scalar(it.Value)).Append('\n'); }
    return o.ToString();
  }

  static void Toml(StringBuilder o,Dictionary<string, object> m,string p){
    if(p!="") o.Append('[').Append(p).Append("]\n");
    foreach(var it in m) if(!(it.Value is Dictionary<string, object>)) o.Append(it.Key).Append(" = ").Append(Scalar(it.Value)).Append('\n');
    foreach(var it in m) if(it.Value is Dictionary<string, object>){ o.Append('\n'); Toml(o,(Dictionary<string, object>)it.Value,p==""?it.Key:p+"."+it.Key); }
  }

  static string Hcl(Dictionary<string, object> m,int n){
    var o=new StringBuilder();
    foreach(var it in m){ var pad=new string(' ',n*2); if(it.Value is Dictionary<string, object>) o.Append(pad).Append(it.Key).Append(" {\n").Append(Hcl((Dictionary<string, object>)it.Value,n+1)).Append(pad).Append("}\n"); else o.Append(pad).Append(it.Key).Append(" = ").Append(Scalar(it.Value)).Append('\n'); }
    return o.ToString();
  }

  static string Scalar(object v){
    if(v is string) return "\""+((string)v).Replace("\\","\\\\").Replace("\"","\\\"").Replace("\n","\\n").Replace("\t","\\t")+"\"";
    if(v is bool) return ((bool)v)?"true":"false";
    if(v is IList){ var a=(IList)v; var o="["; for(int i=0;i<a.Count;i++){ if(i>0) o+=", "; o+=Scalar(a[i]); } return o+"]"; }
    if(v is double) return ((double)v).ToString(System.Globalization.CultureInfo.InvariantCulture);
    return v.ToString();
  }
}
}
