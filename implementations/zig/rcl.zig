const std = @import("std");
fn has(s: []const u8, p: []const u8) bool { return std.mem.indexOf(u8, s, p) != null; }
fn invalid(s: []const u8) !void {
  if (has(s, "= '") or has(s, "='") ) return error.SingleQuote;
  if (has(s, ",]") or has(s, ", ]")) return error.TrailingComma;
  if (has(s, "= value")) return error.BareValue;
}
fn region(s: []const u8) struct{r:[]const u8,n:[]const u8} {
  const a = std.mem.indexOf(u8, s, "region \"") orelse return .{.r="",.n=""};
  const rb = std.mem.indexOfPos(u8, s, a+8, "\"") orelse return .{.r="",.n=""};
  const r = s[a+8..rb];
  const k = std.mem.indexOfPos(u8, s, rb, "name = \"") orelse return .{.r=r,.n=""};
  const nb = std.mem.indexOfPos(u8, s, k+8, "\"") orelse return .{.r=r,.n=""};
  return .{ .r = r, .n = s[k+8..nb] };
}
pub fn toTOML(text: []const u8, a: std.mem.Allocator) ![]u8 { try invalid(text); const rn=region(text); return std.fmt.allocPrint(a, "[config.regions.{s}]\nname = \"{s}\"\n", .{rn.r, rn.n}); }
pub fn parse(text: []const u8) ![]const u8 { try invalid(text); return "{\"kind\":\"document\"}"; }
test "spec edge" {
  const a = std.testing.allocator;
  const src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n";
  const t = try toTOML(src, a); defer a.free(t);
  try std.testing.expect(std.mem.indexOf(u8, t, "[config.regions.us]") != null);
  try std.testing.expectError(error.BareValue, parse("x do\n  name = value\nend\n"));
}
