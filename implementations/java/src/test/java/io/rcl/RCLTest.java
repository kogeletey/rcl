package io.rcl;
public final class RCLTest {
  public static void main(String[] args) throws Exception {
    String src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
    if (!RCL.toTOML(src).contains("[config.regions.us]")) throw new RuntimeException("toml");
    boolean ok = false;
    try { RCL.parse("x do\n  name = value\nend\n"); } catch (RuntimeException ex) { ok = true; }
    if (!ok) throw new RuntimeException("edge");
    System.out.println("ok");
  }
}
