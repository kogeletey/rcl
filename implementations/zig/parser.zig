const std = @import("std");

pub const ParseError = error{ UnexpectedChar, SingleQuote, UnterminatedString, InvalidEscape, UnexpectedToken, MissingEnd, MissingRBracket, BareValue, TrailingComma, KeyConflict, OutOfMemory };

pub const Value = union(enum) { str: []const u8, num: []const u8, bool: bool, arr: std.ArrayList(Value), blk: Block };
pub const Prop = struct { key: []const u8, val: Value };
pub const Block = struct { name: []const u8, arg: ?[]const u8, props: std.ArrayList(Prop), kids: std.ArrayList(Block) };
pub const Doc = struct { blocks: std.ArrayList(Block), root: ?Value = null };

const Tok = enum { id, str, num, eq, comma, dot, lb, rb, kw_do, kw_end, eof };
const Token = struct { t: Tok, v: []const u8, line: usize, col: usize };

const Lexer = struct {
    s: []const u8,
    i: usize = 0,
    line: usize = 1,
    col: usize = 1,

    fn eof(self: *Lexer) bool { return self.i >= self.s.len; }
    fn cur(self: *Lexer) u8 { return self.s[self.i]; }
    fn peek(self: *Lexer) u8 { return if (self.i + 1 < self.s.len) self.s[self.i + 1] else 0; }
    fn adv(self: *Lexer) void {
        if (self.eof()) return;
        if (self.cur() == '\n') {
            self.line += 1;
            self.col = 1;
        } else self.col += 1;
        self.i += 1;
    }
    fn skip(self: *Lexer) void {
        while (!self.eof()) {
            if (std.ascii.isWhitespace(self.cur())) self.adv() else if (self.cur() == '#') {
                while (!self.eof() and self.cur() != '\n') self.adv();
            } else break;
        }
    }
    fn next(self: *Lexer) ParseError!Token {
        self.skip();
        if (self.eof()) return .{ .t = .eof, .v = "", .line = self.line, .col = self.col };
        const line = self.line;
        const col = self.col;
        const c = self.cur();
        if (c == '=') {
            self.adv();
            return .{ .t = .eq, .v = "=", .line = line, .col = col };
        }
        if (c == ',') {
            self.adv();
            return .{ .t = .comma, .v = ",", .line = line, .col = col };
        }
        if (c == '.') {
            self.adv();
            return .{ .t = .dot, .v = ".", .line = line, .col = col };
        }
        if (c == '[') {
            self.adv();
            return .{ .t = .lb, .v = "[", .line = line, .col = col };
        }
        if (c == ']') {
            self.adv();
            return .{ .t = .rb, .v = "]", .line = line, .col = col };
        }
        if (c == '\'') return ParseError.SingleQuote;
        if (c == '"') {
            var b = std.ArrayList(u8).init(std.heap.page_allocator);
            self.adv();
            while (!self.eof() and self.cur() != '"') {
                if (self.cur() == '\\') {
                    self.adv();
                    if (self.eof()) return ParseError.UnterminatedString;
                    switch (self.cur()) {
                        '"' => try b.append('"'),
                        '\\' => try b.append('\\'),
                        'n' => try b.append('\n'),
                        't' => try b.append('\t'),
                        else => return ParseError.InvalidEscape,
                    }
                    self.adv();
                    continue;
                }
                try b.append(self.cur());
                self.adv();
            }
            if (self.eof()) return ParseError.UnterminatedString;
            self.adv();
            return .{ .t = .str, .v = try b.toOwnedSlice(), .line = line, .col = col };
        }
        if ((c == '-' and std.ascii.isDigit(self.peek())) or std.ascii.isDigit(c)) {
            const s = self.i;
            if (c == '-') self.adv();
            while (!self.eof() and std.ascii.isDigit(self.cur())) self.adv();
            if (!self.eof() and self.cur() == '.' and std.ascii.isDigit(self.peek())) {
                self.adv();
                while (!self.eof() and std.ascii.isDigit(self.cur())) self.adv();
            }
            return .{ .t = .num, .v = self.s[s..self.i], .line = line, .col = col };
        }
        if (std.ascii.isAlphabetic(c) or c == '_') {
            const s = self.i;
            while (!self.eof() and (std.ascii.isAlphanumeric(self.cur()) or self.cur() == '_')) self.adv();
            const id = self.s[s..self.i];
            if (std.mem.eql(u8, id, "do")) return .{ .t = .kw_do, .v = id, .line = line, .col = col };
            if (std.mem.eql(u8, id, "end")) return .{ .t = .kw_end, .v = id, .line = line, .col = col };
            return .{ .t = .id, .v = id, .line = line, .col = col };
        }
        return ParseError.UnexpectedChar;
    }
};

const Parser = struct {
    a: std.mem.Allocator,
    lx: Lexer,
    cur: Token,

    fn init(a: std.mem.Allocator, s: []const u8) !Parser {
        var p = Parser{ .a = a, .lx = .{ .s = s }, .cur = undefined };
        p.cur = try p.lx.next();
        return p;
    }
    fn eat(self: *Parser, t: Tok) !void {
        if (self.cur.t != t) return ParseError.UnexpectedToken;
        self.cur = try self.lx.next();
    }
    fn keyConflict(b: Block, k: []const u8) bool {
        for (b.props.items) |p| {
            if (std.mem.eql(u8, p.key, k)) return true;
            if (std.mem.startsWith(u8, p.key, k) and p.key.len > k.len and p.key[k.len] == '.') return true;
            if (std.mem.startsWith(u8, k, p.key) and k.len > p.key.len and k[p.key.len] == '.') return true;
        }
        return false;
    }
    fn parseKey(self: *Parser) ![]const u8 {
        if (self.cur.t != .id) return ParseError.UnexpectedToken;
        var b = std.ArrayList(u8).init(self.a);
        try b.appendSlice(self.cur.v);
        try self.eat(.id);
        while (self.cur.t == .dot) {
            try self.eat(.dot);
            if (self.cur.t != .id) return ParseError.UnexpectedToken;
            try b.append('.');
            try b.appendSlice(self.cur.v);
            try self.eat(.id);
        }
        return b.toOwnedSlice();
    }
    fn parseValue(self: *Parser) !Value {
        if (self.cur.t == .str) {
            const v = self.cur.v;
            try self.eat(.str);
            return .{ .str = v };
        }
        if (self.cur.t == .num) {
            const v = self.cur.v;
            try self.eat(.num);
            return .{ .num = v };
        }
        if (self.cur.t == .id) {
            const v = self.cur.v;
            try self.eat(.id);
            if (std.mem.eql(u8, v, "true")) return .{ .bool = true };
            if (std.mem.eql(u8, v, "false")) return .{ .bool = false };
            return ParseError.BareValue;
        }
        if (self.cur.t == .kw_do) {
            return .{ .blk = try self.parseAnonymousBlock() };
        }
        if (self.cur.t == .lb) {
            try self.eat(.lb);
            var arr = std.ArrayList(Value).init(self.a);
            if (self.cur.t != .rb) {
                try arr.append(try self.parseValue());
                while (self.cur.t == .comma) {
                    try self.eat(.comma);
                    if (self.cur.t == .rb) return ParseError.TrailingComma;
                    try arr.append(try self.parseValue());
                }
            }
            if (self.cur.t != .rb) return ParseError.MissingRBracket;
            try self.eat(.rb);
            return .{ .arr = arr };
        }
        return ParseError.UnexpectedToken;
    }

    fn parseBlockBody(self: *Parser, b: *Block) !void {
        while (self.cur.t != .kw_end) {
            if (self.cur.t == .eof) return ParseError.MissingEnd;
            if (self.cur.t != .id) return ParseError.UnexpectedToken;
            const save = self.lx;
            const tok = self.cur;
            var s = save;
            const nx = try s.next();
            self.lx = save;
            self.cur = tok;
            if (nx.t == .kw_do) {
                var s2 = save;
                _ = try s2.next();
                const nx2 = try s2.next();
                if (nx2.t == .lb) {
                    const key = self.cur.v;
                    if (keyConflict(b.*, key)) return ParseError.KeyConflict;
                    try self.eat(.id);
                    try self.eat(.kw_do);
                    const val = try self.parseValue();
                    switch (val) {
                        .arr => {},
                        else => return ParseError.UnexpectedToken,
                    }
                    try self.eat(.kw_end);
                    try b.props.append(.{ .key = key, .val = val });
                    continue;
                }
            }
            if (nx.t == .kw_do or nx.t == .str) {
                try b.kids.append(try self.parseBlock());
                continue;
            }
            if (nx.t == .eq or nx.t == .dot) {
                const key = try self.parseKey();
                if (keyConflict(b.*, key)) return ParseError.KeyConflict;
                try self.eat(.eq);
                try b.props.append(.{ .key = key, .val = try self.parseValue() });
                continue;
            }
            return ParseError.UnexpectedToken;
        }
    }

    fn parseBlock(self: *Parser) !Block {
        if (self.cur.t != .id) return ParseError.UnexpectedToken;
        var b = Block{ .name = self.cur.v, .arg = null, .props = std.ArrayList(Prop).init(self.a), .kids = std.ArrayList(Block).init(self.a) };
        try self.eat(.id);
        if (self.cur.t == .str) {
            b.arg = self.cur.v;
            try self.eat(.str);
        }
        try self.eat(.kw_do);
        try self.parseBlockBody(&b);
        try self.eat(.kw_end);
        return b;
    }

    fn parseAnonymousBlock(self: *Parser) !Block {
        var b = Block{ .name = "", .arg = null, .props = std.ArrayList(Prop).init(self.a), .kids = std.ArrayList(Block).init(self.a) };
        try self.eat(.kw_do);
        try self.parseBlockBody(&b);
        try self.eat(.kw_end);
        return b;
    }
};

pub fn parseDoc(text: []const u8, a: std.mem.Allocator) !Doc {
    var p = try Parser.init(a, text);
    var d = Doc{ .blocks = std.ArrayList(Block).init(a) };
    if (p.cur.t == .kw_do) {
        try p.eat(.kw_do);
        if (p.cur.t != .lb) return ParseError.UnexpectedToken;
        d.root = try p.parseValue();
        if (p.cur.t != .eof) return ParseError.UnexpectedToken;
        return d;
    }
    while (p.cur.t != .eof) try d.blocks.append(try p.parseBlock());
    return d;
}
