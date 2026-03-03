const std = @import("std");
const P = @import("parser.zig");
const E = @import("emit.zig");

pub fn parse(text: []const u8) ![]const u8 {
    _ = try P.parseDoc(text, std.heap.page_allocator);
    return "{\"kind\":\"document\"}";
}

pub fn format(text: []const u8, a: std.mem.Allocator) ![]u8 {
    const d = try P.parseDoc(text, a);
    var out = std.ArrayList(u8).init(a);
    if (d.root) |root| {
        try out.writer().writeAll("do ");
        try fmtValue(root, out.writer());
        return out.toOwnedSlice();
    }
    try fmtBlocks(d.blocks.items, out.writer(), 0);
    return out.toOwnedSlice();
}

fn fmtInlineBlock(b: P.Block, w: anytype) !void {
    try w.writeAll("do");
    for (b.props.items) |p| {
        try w.writeByte(' ');
        try w.writeAll(p.key);
        switch (p.val) {
            .arr => {
                try w.writeAll(" do ");
                try fmtValue(p.val, w);
                try w.writeAll(" end");
            },
            else => {
                try w.writeAll(" = ");
                try fmtValue(p.val, w);
            },
        }
    }
    for (b.kids.items) |k| {
        try w.writeByte(' ');
        try w.writeAll(k.name);
        if (k.arg) |arg| try w.print(" \"{s}\"", .{arg});
        try w.writeByte(' ');
        try fmtInlineBlock(k, w);
    }
    try w.writeAll(" end");
}

fn fmtValue(v: P.Value, w: anytype) !void {
    switch (v) {
        .str => |s| try w.print("\"{s}\"", .{s}),
        .num => |n| try w.writeAll(n),
        .bool => |b| try w.writeAll(if (b) "true" else "false"),
        .blk => |b| try fmtInlineBlock(b, w),
        .arr => |arr| {
            try w.writeByte('[');
            for (arr.items, 0..) |x, i| {
                if (i > 0) try w.writeAll(", ");
                try fmtValue(x, w);
            }
            try w.writeByte(']');
        },
    }
}

fn fmtBlocks(items: []const P.Block, w: anytype, depth: usize) !void {
    for (items) |b| {
        try w.writeByteNTimes(' ', depth * 2);
        try w.writeAll(b.name);
        if (b.arg) |arg| try w.print(" \"{s}\"", .{arg});
        try w.writeAll(" do\n");
        for (b.props.items) |p| {
            try w.writeByteNTimes(' ', (depth + 1) * 2);
            switch (p.val) {
                .arr => {
                    try w.print("{s} do ", .{p.key});
                    try fmtValue(p.val, w);
                    try w.writeAll(" end\n");
                },
                else => {
                    try w.print("{s} = ", .{p.key});
                    try fmtValue(p.val, w);
                    try w.writeByte('\n');
                },
            }
        }
        try fmtBlocks(b.kids.items, w, depth + 1);
        try w.writeByteNTimes(' ', depth * 2);
        try w.writeAll("end\n");
    }
}

fn convert(text: []const u8, a: std.mem.Allocator, mode: enum { json, yaml, toml, hcl }) ![]u8 {
    const d = try P.parseDoc(text, a);
    const root = try E.project(d, a);
    var out = std.ArrayList(u8).init(a);
    switch (mode) {
        .json => try E.emitJson(root, out.writer()),
        .yaml => try E.emitYaml(root, out.writer(), 0),
        .toml => try E.emitToml(root, out.writer(), ""),
        .hcl => try E.emitHcl(root, out.writer(), 0),
    }
    return out.toOwnedSlice();
}

pub fn toObject(text: []const u8, a: std.mem.Allocator) ![]u8 { return convert(text, a, .json); }
pub fn toYAML(text: []const u8, a: std.mem.Allocator) ![]u8 { return convert(text, a, .yaml); }
pub fn toTOML(text: []const u8, a: std.mem.Allocator) ![]u8 { return convert(text, a, .toml); }
pub fn toHCL(text: []const u8, a: std.mem.Allocator) ![]u8 { return convert(text, a, .hcl); }

test "spec parse/project/converters" {
    const a = std.heap.page_allocator;
    const src = "config do\n  tls.cert = \"/x\"\n  tests do [do name = \"smoke\" end, 1] end\n  legacy = [1, 2]\n  region \"us\" do\n    name = \"My Name\"\n    ports = [1, 2]\n  end\nend\n";
    const obj = try toObject(src, a);
    try std.testing.expect(std.mem.indexOf(u8, obj, "\"config\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, obj, "\"regions\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, obj, "\"us\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, obj, "\"name\":\"My Name\"") != null);
    const fmt = try format(src, a);
    try std.testing.expect(std.mem.indexOf(u8, fmt, "tests do [do name = \"smoke\" end, 1] end") != null);
    try std.testing.expect(std.mem.indexOf(u8, fmt, "legacy do [1, 2] end") != null);
    const toml = try toTOML(src, a); defer a.free(toml);
    try std.testing.expect(std.mem.indexOf(u8, toml, "[config.regions.us]") != null);
    const root = try toObject("do [do type = \"smoke\" end, \"string\", [1, 2, 3]]", a);
    try std.testing.expect(std.mem.indexOf(u8, root, "\"root\":[") != null);
    try std.testing.expect(std.mem.indexOf(u8, root, "\"type\":\"smoke\"") != null);
}

test "spec edges" {
    const a = std.heap.page_allocator;
    try std.testing.expectError(P.ParseError.BareValue, P.parseDoc("x do\n  name = value\nend\n", a));
    try std.testing.expectError(P.ParseError.TrailingComma, P.parseDoc("x do\n  arr = [1,]\nend\n", a));
    try std.testing.expectError(P.ParseError.KeyConflict, P.parseDoc("x do\n  a = 1\n  a.b = 2\nend\n", a));
    try std.testing.expectError(P.ParseError.SingleQuote, P.parseDoc("x do\n  s = 'bad'\nend\n", a));
    try std.testing.expectError(P.ParseError.InvalidEscape, P.parseDoc("x do\n  s = \"bad\\q\"\nend\n", a));
    try std.testing.expectError(P.ParseError.MissingEnd, P.parseDoc("x do\n  tests do [\"a\", \"b\"]\nend\n", a));
    try std.testing.expectError(P.ParseError.MissingRBracket, P.parseDoc("do [\"a\", \"b\"", a));
    try std.testing.expectError(P.ParseError.UnexpectedToken, P.parseDoc("x do\n  tests = [do name = \"broken\"]\nend\n", a));
}
