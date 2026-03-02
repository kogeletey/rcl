package rcl

import "unicode"

type lexer struct {
	input  []rune
	pos    int
	line   int
	column int
}

type lexerState struct{ pos, line, column int }

func newLexer(s string) *lexer { return &lexer{input: []rune(s), line: 1, column: 1} }
func (l *lexer) snapshot() lexerState { return lexerState{l.pos, l.line, l.column} }
func (l *lexer) restore(st lexerState) { l.pos, l.line, l.column = st.pos, st.line, st.column }

func (l *lexer) nextToken() (token, error) {
	l.skip()
	if l.eof() { return token{typ: tokEOF, line: l.line, col: l.column}, nil }
	line, col, ch := l.line, l.column, l.cur()
	switch ch {
	case '=':
		l.adv(); return token{typ: tokEqual, value: "=", line: line, col: col}, nil
	case ',':
		l.adv(); return token{typ: tokComma, value: ",", line: line, col: col}, nil
	case '.':
		l.adv(); return token{typ: tokDot, value: ".", line: line, col: col}, nil
	case '[':
		l.adv(); return token{typ: tokLBracket, value: "[", line: line, col: col}, nil
	case ']':
		l.adv(); return token{typ: tokRBracket, value: "]", line: line, col: col}, nil
	case '"':
		return l.readString(line, col)
	}
	if ch == '-' && unicode.IsDigit(l.peek()) || unicode.IsDigit(ch) { return l.readNumber(line, col), nil }
	if unicode.IsLetter(ch) || ch == '_' { return l.readIdent(line, col), nil }
	return token{}, &ParseError{Message: "unexpected character", Line: line, Column: col}
}

func (l *lexer) readString(line, col int) (token, error) {
	l.adv()
	out := []rune{}
	for !l.eof() && l.cur() != '"' {
		if l.cur() == '\\' {
			l.adv()
			if l.eof() { return token{}, &ParseError{Message: "unterminated escape", Line: line, Column: col} }
			switch l.cur() {
			case '"': out = append(out, '"')
			case 'n': out = append(out, '\n')
			case 't': out = append(out, '\t')
			case '\\': out = append(out, '\\')
			default: return token{}, &ParseError{Message: "invalid escape", Line: l.line, Column: l.column}
			}
			l.adv(); continue
		}
		out = append(out, l.cur())
		l.adv()
	}
	if l.eof() { return token{}, &ParseError{Message: "unterminated string", Line: line, Column: col} }
	l.adv()
	return token{typ: tokString, value: string(out), line: line, col: col}, nil
}

func (l *lexer) readNumber(line, col int) token {
	out := []rune{}
	if l.cur() == '-' { out = append(out, '-'); l.adv() }
	for !l.eof() && unicode.IsDigit(l.cur()) { out = append(out, l.cur()); l.adv() }
	if !l.eof() && l.cur() == '.' && unicode.IsDigit(l.peek()) {
		out = append(out, '.')
		l.adv()
		for !l.eof() && unicode.IsDigit(l.cur()) { out = append(out, l.cur()); l.adv() }
	}
	return token{typ: tokNumber, value: string(out), line: line, col: col}
}

func (l *lexer) readIdent(line, col int) token {
	out := []rune{}
	for !l.eof() && (unicode.IsLetter(l.cur()) || unicode.IsDigit(l.cur()) || l.cur() == '_') { out = append(out, l.cur()); l.adv() }
	if string(out) == "do" { return token{typ: tokDo, value: "do", line: line, col: col} }
	if string(out) == "end" { return token{typ: tokEnd, value: "end", line: line, col: col} }
	return token{typ: tokIdentifier, value: string(out), line: line, col: col}
}

func (l *lexer) skip() {
	for !l.eof() {
		if unicode.IsSpace(l.cur()) { l.adv(); continue }
		if l.cur() == '#' { for !l.eof() && l.cur() != '\n' { l.adv() }; continue }
		break
	}
}

func (l *lexer) adv() {
	if l.eof() { return }
	if l.cur() == '\n' { l.line++; l.column = 1 } else { l.column++ }
	l.pos++
}
func (l *lexer) cur() rune { return l.input[l.pos] }
func (l *lexer) peek() rune { if l.pos+1 >= len(l.input) { return 0 }; return l.input[l.pos+1] }
func (l *lexer) eof() bool { return l.pos >= len(l.input) }
