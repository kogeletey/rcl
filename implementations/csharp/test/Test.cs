using System;
using RCLImpl;
class Test {
  static int Main() {
    var src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
    if (!RCL.ToTOML(src).Contains("[config.regions.us]")) return 1;
    var ok = false;
    try { RCL.Parse("x do\n  name = value\nend\n"); } catch { ok = true; }
    return ok ? 0 : 1;
  }
}
