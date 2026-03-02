package io.rcl;

import java.util.Map;

public final class RCL {
  private RCL() {}

  public static DocumentNode parse(String text) { return new Parser(text).parse(); }
  public static String format(String text) { return Formatter.format(parse(text)); }
  public static String format(DocumentNode doc) { return Formatter.format(doc); }
  public static Map<String, Object> toObject(String text) { return Converters.toObject(parse(text)); }
  public static Map<String, Object> toObject(DocumentNode doc) { return Converters.toObject(doc); }
  public static String toYAML(String text) { return Converters.toYAML(parse(text)); }
  public static String toYAML(DocumentNode doc) { return Converters.toYAML(doc); }
  public static String toTOML(String text) { return Converters.toTOML(parse(text)); }
  public static String toTOML(DocumentNode doc) { return Converters.toTOML(doc); }
  public static String toHCL(String text) { return Converters.toHCL(parse(text)); }
  public static String toHCL(DocumentNode doc) { return Converters.toHCL(doc); }
}
