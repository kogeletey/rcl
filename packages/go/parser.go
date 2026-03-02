package rcl

import "strconv"

type parser struct {
	lex *lexer
	cur token
}

func Parse(text string) (DocumentNode, error) {
	p := &parser{lex: newLexer(text)}
	t, err := p.lex.nextToken()
	if err != nil { return DocumentNode{}, err }
	p.cur = t
	return p.parse()
}

func (p *parser) parse() (DocumentNode, error) {
	blocks := []BlockNode{}
	for p.cur.typ != tokEOF {
		b, err := p.parseBlock()
		if err != nil { return DocumentNode{}, err }
		blocks = append(blocks, b)
	}
	return DocumentNode{NodeKind: "document", Blocks: blocks}, nil
}

func (p *parser) parseBlock() (BlockNode, error) {
	name := p.cur.value
	if err := p.eat(tokIdentifier); err != nil { return BlockNode{}, err }
	var arg *string
	if p.cur.typ == tokString { v := p.cur.value; arg = &v; _ = p.eat(tokString) }
	if err := p.eat(tokDo); err != nil { return BlockNode{}, err }

	props := map[string]Node{}
	blocks := map[string]BlockNode{}
	named := []BlockNode{}

	for p.cur.typ != tokEnd {
		if p.cur.typ == tokEOF { return BlockNode{}, p.err("missing end") }
		if p.cur.typ != tokIdentifier { return BlockNode{}, p.err("expected identifier") }
		next, err := p.peek()
		if err != nil { return BlockNode{}, err }
		if next.typ == tokDo || next.typ == tokString {
			child, err := p.parseBlock()
			if err != nil { return BlockNode{}, err }
			if child.Argument != nil {
				named = append(named, child)
				blocks[child.Name+":"+*child.Argument] = child
			} else { blocks[child.Name] = child }
		} else if next.typ == tokEqual || next.typ == tokDot {
			k, err := p.parseKey()
			if err != nil { return BlockNode{}, err }
			if err = p.eat(tokEqual); err != nil { return BlockNode{}, err }
			v, err := p.parseValue()
			if err != nil { return BlockNode{}, err }
			props[k] = v
		} else { return BlockNode{}, p.err("invalid statement") }
	}
	if err := p.eat(tokEnd); err != nil { return BlockNode{}, err }
	b := BlockNode{NodeKind: "block", Name: name, Argument: arg, Properties: props, Blocks: blocks}
	if len(named) > 0 { b.NamedBlocks = named }
	return b, nil
}

func (p *parser) parseKey() (string, error) {
	key := p.cur.value
	if err := p.eat(tokIdentifier); err != nil { return "", err }
	for p.cur.typ == tokDot {
		if err := p.eat(tokDot); err != nil { return "", err }
		if p.cur.typ != tokIdentifier { return "", p.err("expected identifier after dot") }
		key += "." + p.cur.value
		if err := p.eat(tokIdentifier); err != nil { return "", err }
	}
	return key, nil
}

func (p *parser) parseValue() (Node, error) {
	switch p.cur.typ {
	case tokString:
		v := StringNode{NodeKind: "string", Value: p.cur.value}; _ = p.eat(tokString); return v, nil
	case tokNumber:
		n, err := strconv.ParseFloat(p.cur.value, 64)
		if err != nil { return nil, p.err("invalid number") }
		_ = p.eat(tokNumber); return NumberNode{NodeKind: "number", Value: n}, nil
	case tokIdentifier:
		v := p.cur.value; _ = p.eat(tokIdentifier)
		if v == "true" { return BooleanNode{NodeKind: "boolean", Value: true}, nil }
		if v == "false" { return BooleanNode{NodeKind: "boolean", Value: false}, nil }
		return StringNode{NodeKind: "string", Value: v}, nil
	case tokLBracket:
		return p.parseArray()
	default:
		return nil, p.err("unexpected value")
	}
}

func (p *parser) parseArray() (Node, error) {
	if err := p.eat(tokLBracket); err != nil { return nil, err }
	elems := []Node{}
	if p.cur.typ != tokRBracket {
		v, err := p.parseValue(); if err != nil { return nil, err }
		elems = append(elems, v)
		for p.cur.typ == tokComma {
			_ = p.eat(tokComma)
			v, err = p.parseValue(); if err != nil { return nil, err }
			elems = append(elems, v)
		}
	}
	if err := p.eat(tokRBracket); err != nil { return nil, err }
	return ArrayNode{NodeKind: "array", Elements: elems}, nil
}

func (p *parser) eat(tt tokenType) error {
	if p.cur.typ != tt { return p.err("unexpected token") }
	n, err := p.lex.nextToken()
	if err != nil { return err }
	p.cur = n
	return nil
}
func (p *parser) peek() (token, error) {
	st := p.lex.snapshot()
	t, err := p.lex.nextToken()
	p.lex.restore(st)
	return t, err
}
func (p *parser) err(msg string) error { return &ParseError{Message: msg, Line: p.cur.line, Column: p.cur.col} }
