package io.rcl

class Parser private constructor(private val lexer: Lexer) {
  private var current: Token = lexer.nextToken()

  companion object {
    fun parse(text: String): DocumentNode = Parser(Lexer(text)).parse()
  }

  fun parse(): DocumentNode {
    val blocks = mutableListOf<BlockNode>()
    while (current.type != TokenType.EOF) blocks += parseBlock()
    return DocumentNode(blocks = blocks)
  }

  private fun parseBlock(): BlockNode {
    val name = current.value
    eat(TokenType.Identifier)

    var argument: String? = null
    if (current.type == TokenType.String) { argument = current.value; eat(TokenType.String) }
    eat(TokenType.Do)

    val properties = linkedMapOf<String, AstNode>()
    val blocks = linkedMapOf<String, BlockNode>()
    val named = mutableListOf<BlockNode>()

    while (current.type != TokenType.End) {
      if (current.type == TokenType.EOF) throw error("missing end")
      if (current.type != TokenType.Identifier) throw error("expected identifier")
      when (peekToken().type) {
        TokenType.Do, TokenType.String -> {
          val child = parseBlock()
          if (child.argument != null) {
            named += child
            blocks["${child.name}:${child.argument}"] = child
          } else blocks[child.name] = child
        }
        TokenType.Equal, TokenType.Dot -> {
          val key = parsePropertyKey()
          eat(TokenType.Equal)
          properties[key] = parseValue()
        }
        else -> throw error("invalid statement")
      }
    }

    eat(TokenType.End)
    return BlockNode(name = name, argument = argument, properties = properties, blocks = blocks, namedBlocks = named)
  }

  private fun parsePropertyKey(): String {
    var key = current.value
    eat(TokenType.Identifier)
    while (current.type == TokenType.Dot) {
      eat(TokenType.Dot)
      if (current.type != TokenType.Identifier) throw error("expected identifier after dot")
      key += ".${current.value}"
      eat(TokenType.Identifier)
    }
    return key
  }

  private fun parseValue(): AstNode = when (current.type) {
    TokenType.String -> StringNode(value = current.value).also { eat(TokenType.String) }
    TokenType.Number -> NumberNode(value = current.value.toDouble()).also { eat(TokenType.Number) }
    TokenType.Identifier -> {
      val v = current.value
      eat(TokenType.Identifier)
      when (v) { "true" -> BooleanNode(value = true); "false" -> BooleanNode(value = false); else -> StringNode(value = v) }
    }
    TokenType.LBracket -> parseArray()
    else -> throw error("unexpected value")
  }

  private fun parseArray(): AstNode {
    eat(TokenType.LBracket)
    val elements = mutableListOf<AstNode>()
    if (current.type != TokenType.RBracket) {
      elements += parseValue()
      while (current.type == TokenType.Comma) { eat(TokenType.Comma); elements += parseValue() }
    }
    eat(TokenType.RBracket)
    return ArrayNode(elements = elements)
  }

  private fun eat(type: TokenType) {
    if (current.type != type) throw error("expected $type, got ${current.type}")
    current = lexer.nextToken()
  }

  private fun peekToken(): Token {
    val st = lexer.snapshot()
    val tok = lexer.nextToken()
    lexer.restore(st)
    return tok
  }

  private fun error(message: String): ParseError = ParseError(message, current.line, current.column)
}
