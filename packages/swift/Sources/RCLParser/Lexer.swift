enum TokenType { case identifier, string, number, equal, comma, dot, `do`, end, lbracket, rbracket, eof }
struct Token { let type: TokenType; let value: String; let line: Int; let column: Int }
struct LexerState { let pos: Int; let line: Int; let col: Int }

final class Lexer {
    private let input: [Character]
    private var pos = 0
    private var line = 1
    private var col = 1

    init(_ text: String) { self.input = Array(text) }

    func snapshot() -> LexerState { .init(pos: pos, line: line, col: col) }
    func restore(_ st: LexerState) { pos = st.pos; line = st.line; col = st.col }

    func nextToken() throws -> Token {
        skip()
        if eof { return .init(type: .eof, value: "", line: line, column: col) }
        let (l, c, ch) = (line, col, cur)
        switch ch {
        case "=": adv(); return .init(type: .equal, value: "=", line: l, column: c)
        case ",": adv(); return .init(type: .comma, value: ",", line: l, column: c)
        case ".": adv(); return .init(type: .dot, value: ".", line: l, column: c)
        case "[": adv(); return .init(type: .lbracket, value: "[", line: l, column: c)
        case "]": adv(); return .init(type: .rbracket, value: "]", line: l, column: c)
        case "\"": return try readString(line: l, column: c)
        default:
            if ch.isNumber || (ch == "-" && peek.isNumber) { return readNumber(line: l, column: c) }
            if ch.isLetter || ch == "_" { return readIdentifier(line: l, column: c) }
            throw ParseError("unexpected character", line: l, column: c)
        }
    }

    private func readString(line: Int, column: Int) throws -> Token {
        adv(); var out = ""
        while !eof && cur != "\"" {
            if cur == "\\" {
                adv(); if eof { throw ParseError("unterminated escape", line: line, column: column) }
                switch cur {
                case "\"": out.append("\"")
                case "n": out.append("\n")
                case "t": out.append("\t")
                case "\\": out.append("\\")
                default: throw ParseError("invalid escape", line: self.line, column: self.col)
                }
                adv()
            } else { out.append(cur); adv() }
        }
        if eof { throw ParseError("unterminated string", line: line, column: column) }
        adv()
        return .init(type: .string, value: out, line: line, column: column)
    }

    private func readNumber(line: Int, column: Int) -> Token {
        var out = ""
        if cur == "-" { out.append("-"); adv() }
        while !eof && cur.isNumber { out.append(cur); adv() }
        if !eof && cur == "." && peek.isNumber { out.append("."); adv(); while !eof && cur.isNumber { out.append(cur); adv() } }
        return .init(type: .number, value: out, line: line, column: column)
    }

    private func readIdentifier(line: Int, column: Int) -> Token {
        var out = ""
        while !eof && (cur.isLetter || cur.isNumber || cur == "_") { out.append(cur); adv() }
        if out == "do" { return .init(type: .do, value: out, line: line, column: column) }
        if out == "end" { return .init(type: .end, value: out, line: line, column: column) }
        return .init(type: .identifier, value: out, line: line, column: column)
    }

    private func skip() {
        while !eof {
            if cur.isWhitespace { adv() }
            else if cur == "#" { while !eof && cur != "\n" { adv() } }
            else { break }
        }
    }

    private var eof: Bool { pos >= input.count }
    private var cur: Character { input[pos] }
    private var peek: Character { pos + 1 < input.count ? input[pos + 1] : "\0" }
    private func adv() { if eof { return }; if cur == "\n" { line += 1; col = 1 } else { col += 1 }; pos += 1 }
}
