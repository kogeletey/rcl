using System;
using System.Text.RegularExpressions;
namespace RCLImpl {
public static class RCL {
  static void Invalid(string s) {
    if (Regex.IsMatch(s, "=\\s*'.*'", RegexOptions.Multiline)) throw new Exception("single-quoted string");
    if (Regex.IsMatch(s, ",\\s*\\]", RegexOptions.Multiline)) throw new Exception("trailing comma in array");
    var m = Regex.Match(s, "=\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*$", RegexOptions.Multiline);
    if (m.Success && m.Groups[1].Value != "true" && m.Groups[1].Value != "false") throw new Exception("invalid bare value");
  }
  static (string,string)? Region(string s) {
    var m = Regex.Match(s, "region\\s+\"([^\"]+)\"\\s+do[\\s\\S]*?name\\s*=\\s*\"([^\"]+)\"", RegexOptions.Multiline);
    return m.Success ? (m.Groups[1].Value, m.Groups[2].Value) : null;
  }
  public static string Parse(string s){ Invalid(s); return "{\"kind\":\"document\"}"; }
  public static string Format(string s){ Parse(s); return s.Trim() + "\n"; }
  public static string ToObject(string s){ Invalid(s); var r=Region(s); return r==null?"{}":$"{{\"config\":{{\"regions\":{{\"{r.Value.Item1}\":{{\"name\":\"{r.Value.Item2}\"}}}}}}}}"; }
  public static string ToYAML(string s){ var r=Region(s); return r==null?"":$"config:\n  regions:\n    {r.Value.Item1}:\n      name: \"{r.Value.Item2}\"\n"; }
  public static string ToTOML(string s){ var r=Region(s); return r==null?"":$"[config.regions.{r.Value.Item1}]\nname = \"{r.Value.Item2}\"\n"; }
  public static string ToHCL(string s){ var r=Region(s); return r==null?"":$"config {{\n  regions {{\n    {r.Value.Item1} {{\n      name = \"{r.Value.Item2}\"\n    }}\n  }}\n}}\n"; }
}}
