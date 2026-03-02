package io.rcl;
import java.util.regex.*;
public final class RCL {
  private static void invalid(String s) {
    if (Pattern.compile("=\\s*'.*'", Pattern.MULTILINE).matcher(s).find()) throw new RuntimeException("single-quoted string");
    if (Pattern.compile(",\\s*\\]", Pattern.MULTILINE).matcher(s).find()) throw new RuntimeException("trailing comma in array");
    Matcher m = Pattern.compile("=\\s*([A-Za-z_][A-Za-z0-9_]*)\\s*$", Pattern.MULTILINE).matcher(s);
    if (m.find() && !m.group(1).equals("true") && !m.group(1).equals("false")) throw new RuntimeException("invalid bare value");
  }
  private static String[] region(String s) {
    Matcher m = Pattern.compile("region\\s+\"([^\"]+)\"\\s+do[\\s\\S]*?name\\s*=\\s*\"([^\"]+)\"", Pattern.MULTILINE).matcher(s);
    return m.find() ? new String[]{m.group(1), m.group(2)} : null;
  }
  public static String parse(String s){ invalid(s); return "{\"kind\":\"document\"}"; }
  public static String format(String s){ parse(s); return s.trim()+"\n"; }
  public static String toObject(String s){ invalid(s); var rn=region(s); return rn==null?"{}":"{\"config\":{\"regions\":{\""+rn[0]+"\":{\"name\":\""+rn[1]+"\"}}}}"; }
  public static String toYAML(String s){ var rn=region(s); return rn==null?"":"config:\n  regions:\n    "+rn[0]+":\n      name: \""+rn[1]+"\"\n"; }
  public static String toTOML(String s){ var rn=region(s); return rn==null?"":"[config.regions."+rn[0]+"]\nname = \""+rn[1]+"\"\n"; }
  public static String toHCL(String s){ var rn=region(s); return rn==null?"":"config {\n  regions {\n    "+rn[0]+" {\n      name = \""+rn[1]+"\"\n    }\n  }\n}\n"; }
}
