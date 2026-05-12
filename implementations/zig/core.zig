const std = @import("std");
const E = @import("emit.zig");
const P = @import("parser.zig");

pub const ParseError = P.ParseError;
pub const Value = P.Value;
pub const Prop = P.Prop;
pub const Block = P.Block;
pub const Doc = P.Doc;

pub fn parse(text: []const u8, a: std.mem.Allocator) !Doc {
    return P.parseDoc(text, a);
}

pub fn to_object(doc: Doc, a: std.mem.Allocator) ![]u8 {
    const root = try E.project(doc, a);
    var out = std.ArrayList(u8).init(a);
    try E.emitJson(root, out.writer());
    return out.toOwnedSlice();
}

pub fn toObject(doc: Doc, a: std.mem.Allocator) ![]u8 {
    return to_object(doc, a);
}
