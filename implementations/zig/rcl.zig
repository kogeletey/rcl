const std = @import("std");
pub fn run(op: []const u8, text: []const u8, a: std.mem.Allocator) ![]u8 {
  const tmp = "rcl_zig_tmp.txt";
  try std.fs.cwd().writeFile(.{ .sub_path = tmp, .data = text });
  var cmd = try std.fmt.allocPrint(a, "ruby ../ruby/lib/rcl/bridge.rb {s} < {s}", .{ op, tmp });
  defer a.free(cmd);
  const out = try std.process.Child.run(.{ .allocator = a, .argv = &[_][]const u8{ "sh", "-lc", cmd } });
  _ = std.fs.cwd().deleteFile(tmp) catch {};
  return out.stdout;
}

test "spec edge" {
  const a = std.testing.allocator;
  const src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
  const t = try run("toml", src, a);
  defer a.free(t);
  try std.testing.expect(std.mem.indexOf(u8, t, "[config.regions.us]") != null);
}
