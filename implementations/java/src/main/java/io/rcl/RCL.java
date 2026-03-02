package io.rcl;
import java.io.*;
public final class RCL {
  private static String run(String op, String text) throws Exception {
    String bridge = "../ruby/lib/rcl/bridge.rb";
    Process p = new ProcessBuilder("ruby", bridge, op).directory(new File(".")).start();
    try (OutputStream os = p.getOutputStream()) { os.write(text.getBytes()); }
    String out = new String(p.getInputStream().readAllBytes());
    String err = new String(p.getErrorStream().readAllBytes());
    int code = p.waitFor();
    if (code != 0) throw new RuntimeException(err.isEmpty() ? out : err);
    return out;
  }
  public static String parse(String s) throws Exception { return run("parse", s); }
  public static String format(String s) throws Exception { return run("format", s); }
  public static String toObject(String s) throws Exception { return run("object", s); }
  public static String toYAML(String s) throws Exception { return run("yaml", s); }
  public static String toTOML(String s) throws Exception { return run("toml", s); }
  public static String toHCL(String s) throws Exception { return run("hcl", s); }
}
