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
    val seen = linkedSetOf<String>()

    while (current.type != TokenType.End) {
      if (current.type == TokenType.EOF) throw error("missing end")
      if (current.type != TokenType.Identifier) throw error("expected identifier")
      when (peekToken().type) {
        TokenType.Do, TokenType.String -> {
          val child = parseBlock()
          if (child.argument != null) {
            named += child
          } else blocks[child.name] = child
        }
        TokenType.Equal, TokenType.Dot -> {
          val key = parsePropertyKey()
          ensureKeyValid(key, seen)
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
      when (v) {
        "true" -> BooleanNode(value = true)
        "false" -> BooleanNode(value = false)
        else -> throw error("invalid bare value")
      }
    }
    TokenType.LBracket -> parseArray()
    else -> throw error("unexpected value")
  }

  private fun parseArray(): AstNode {
    eat(TokenType.LBracket)
    val elements = mutableListOf<AstNode>()
    if (current.type != TokenType.RBracket) {
      elements += parseValue()
      while (current.type == TokenType.Comma) {
        eat(TokenType.Comma)
        if (current.type == TokenType.RBracket) throw error("trailing comma in array")
        elements += parseValue()
      }
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

  private fun ensureKeyValid(key: String, seen: MutableSet<String>) {
    if (seen.contains(key)) throw error("duplicate key")
    val parts = key.split(".")
    seen.forEach { existing ->
      val ex = existing.split(".")
      if (isPrefix(parts, ex) || isPrefix(ex, parts)) throw error("key conflict")
    }
    seen.add(key)
  }

  private fun isPrefix(left: List<String>, right: List<String>): Boolean {
    if (left.size >= right.size) return false
    left.indices.forEach { if (left[it] != right[it]) return false }
    return true
  }
}
