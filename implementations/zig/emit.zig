const std = @import("std");
const P = @import("parser.zig");

pub const Node = union(enum) { obj: std.StringArrayHashMap(Node), arr: std.ArrayList(Node), str: []const u8, num: []const u8, bool: bool };

fn base(name: []const u8, a: std.mem.Allocator) ![]const u8 {
    if (name.len > 0 and name[name.len - 1] == 's') return name;
    return try std.fmt.allocPrint(a, "{s}s", .{name});
}
fn nodeOf(v: P.Value, a: std.mem.Allocator) !Node {
    return switch (v) {
        .str => |s| .{ .str = s }, .num => |n| .{ .num = n }, .bool => |b| .{ .bool = b },
        .arr => |arr| blk: { var out = std.ArrayList(Node).init(a); for (arr.items) |x| try out.append(try nodeOf(x, a)); break :blk .{ .arr = out }; },
        .blk => |b| try projBlock(b, a),
    };
}
fn insertPath(obj: *Node, key: []const u8, v: Node, a: std.mem.Allocator) !void {
    const p = std.mem.indexOfScalar(u8, key, '.');
    if (p == null) { try obj.obj.put(key, v); return; }
    const head = key[0..p.?]; const rest = key[p.? + 1 ..];
    if (obj.obj.getPtr(head) == null) try obj.obj.put(head, .{ .obj = std.StringArrayHashMap(Node).init(a) });
    try insertPath(obj.obj.getPtr(head).?, rest, v, a);
}
fn projBlock(b: P.Block, a: std.mem.Allocator) !Node {
    var n = Node{ .obj = std.StringArrayHashMap(Node).init(a) };
    for (b.props.items) |p| try insertPath(&n, p.key, try nodeOf(p.val, a), a);
    for (b.kids.items) |k| if (k.arg == null) try n.obj.put(k.name, try projBlock(k, a));
    for (b.kids.items) |k| if (k.arg != null) {
        const bn = try base(k.name, a);
        if (n.obj.getPtr(bn) == null) try n.obj.put(bn, .{ .obj = std.StringArrayHashMap(Node).init(a) });
        try n.obj.getPtr(bn).?.obj.put(k.arg.?, try projBlock(k, a));
    };
    return n;
}
pub fn project(d: P.Doc, a: std.mem.Allocator) !Node {
    var root = Node{ .obj = std.StringArrayHashMap(Node).init(a) };
    if (d.root) |v| {
        try root.obj.put("root", try nodeOf(v, a));
        return root;
    }
    for (d.blocks.items) |b| {
        if (b.arg) |arg| {
            const bn = try base(b.name, a);
            if (root.obj.getPtr(bn) == null) try root.obj.put(bn, .{ .obj = std.StringArrayHashMap(Node).init(a) });
            try root.obj.getPtr(bn).?.obj.put(arg, try projBlock(b, a));
        } else try root.obj.put(b.name, try projBlock(b, a));
    }
    return root;
}

fn esc(s: []const u8, w: anytype) !void { for (s) |c| switch (c) { '"', '\\' => { try w.print("\\{c}", .{c}); }, '\n' => try w.writeAll("\\n"), '\t' => try w.writeAll("\\t"), else => try w.print("{c}", .{c}) }; }
pub fn emitJson(n: Node, w: anytype) !void {
    switch (n) {
        .obj => |o| { try w.writeByte('{'); var i: usize = 0; var it = o.iterator(); while (it.next()) |e| : (i += 1) { if (i > 0) try w.writeByte(','); try w.writeByte('"'); try esc(e.key_ptr.*, w); try w.writeAll("\":"); try emitJson(e.value_ptr.*, w); } try w.writeByte('}'); },
        .arr => |a| { try w.writeByte('['); for (a.items, 0..) |v, i| { if (i > 0) try w.writeByte(','); try emitJson(v, w); } try w.writeByte(']'); },
        .str => |s| { try w.writeByte('"'); try esc(s, w); try w.writeByte('"'); }, .num => |x| try w.writeAll(x), .bool => |b| try w.writeAll(if (b) "true" else "false"),
    }
}
pub fn emitToml(n: Node, w: anytype, p: []const u8) !void {
    for (n.obj.keys(), n.obj.values()) |k, v| switch (v) {
        .obj => {},
        else => { try w.print("{s} = ", .{k}); try emitJson(v, w); try w.writeByte('\n'); },
    };
    for (n.obj.keys(), n.obj.values()) |k, v| switch (v) {
        .obj => {
            var s = std.ArrayList(u8).init(std.heap.page_allocator);
            if (p.len > 0) try s.writer().print("{s}.{s}", .{ p, k }) else try s.writer().print("{s}", .{k});
            try w.print("\n[{s}]\n", .{s.items});
            try emitToml(v, w, s.items);
        },
        else => {},
    };
}
pub fn emitYaml(n: Node, w: anytype, d: usize) !void {
    switch (n) {
        .obj => |o| { for (o.keys(), o.values()) |k, v| { try w.writeByteNTimes(' ', d * 2); try w.print("{s}:", .{k}); switch (v) { .obj, .arr => { try w.writeByte('\n'); try emitYaml(v, w, d + 1); }, else => { try w.writeByte(' '); try emitJson(v, w); try w.writeByte('\n'); } } } },
        .arr => |a| for (a.items) |v| { try w.writeByteNTimes(' ', d * 2); try w.writeAll("- "); try emitJson(v, w); try w.writeByte('\n'); },
        else => {},
    }
}
pub fn emitHcl(n: Node, w: anytype, d: usize) !void {
    for (n.obj.keys(), n.obj.values()) |k, v| {
        try w.writeByteNTimes(' ', d * 2); try w.writeAll(k);
        switch (v) {
            .obj => { try w.writeAll(" {\n"); try emitHcl(v, w, d + 1); try w.writeByteNTimes(' ', d * 2); try w.writeAll("}\n"); },
            else => { try w.writeAll(" = "); try emitJson(v, w); try w.writeByte('\n'); },
        }
    }
}
