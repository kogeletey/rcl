package rcl

type tokenType int

const (
	tokIdentifier tokenType = iota
	tokString
	tokNumber
	tokEqual
	tokComma
	tokDot
	tokDo
	tokEnd
	tokLBracket
	tokRBracket
	tokEOF
)

type token struct {
	typ   tokenType
	value string
	line  int
	col   int
}
