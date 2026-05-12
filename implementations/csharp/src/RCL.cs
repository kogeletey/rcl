using System.Collections.Generic;

namespace RCLImpl {
public static class RCL {
  public static DocumentNode Parse(string s){ return Core.RCL.Parse(s); }
  public static string Format(string s){ return Formatter.Format(Parse(s)); }
  public static string Format(DocumentNode d){ return Formatter.Format(d); }
  public static Dictionary<string, object> ToObject(string s){ return Core.RCL.ToObject(s); }
  public static Dictionary<string, object> ToObject(DocumentNode d){ return Core.RCL.ToObject(d); }
  public static string ToYAML(string s){ return Converters.ToYAML(Parse(s)); }
  public static string ToYAML(DocumentNode d){ return Converters.ToYAML(d); }
  public static string ToTOML(string s){ return Converters.ToTOML(Parse(s)); }
  public static string ToTOML(DocumentNode d){ return Converters.ToTOML(d); }
  public static string ToHCL(string s){ return Converters.ToHCL(Parse(s)); }
  public static string ToHCL(DocumentNode d){ return Converters.ToHCL(d); }
}
}
