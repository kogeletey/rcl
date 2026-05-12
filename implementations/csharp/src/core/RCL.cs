using System.Collections.Generic;

namespace RCLImpl.Core {
public static class RCL {
  public static DocumentNode Parse(string s){ return new Parser(s).Parse(); }
  public static Dictionary<string, object> ToObject(string s){ return Converters.ToObject(Parse(s)); }
  public static Dictionary<string, object> ToObject(DocumentNode d){ return Converters.ToObject(d); }
}
}
