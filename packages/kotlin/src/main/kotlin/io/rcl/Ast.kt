package io.rcl

sealed interface AstNode { val kind: String }

data class DocumentNode(
  override val kind: String = "document",
  val blocks: List<BlockNode>,
) : AstNode

data class BlockNode(
  override val kind: String = "block",
  val name: String,
  val argument: String? = null,
  val properties: Map<String, AstNode> = emptyMap(),
  val blocks: Map<String, BlockNode> = emptyMap(),
  val namedBlocks: List<BlockNode> = emptyList(),
) : AstNode

data class StringNode(override val kind: String = "string", val value: String) : AstNode

data class NumberNode(override val kind: String = "number", val value: Double) : AstNode

data class BooleanNode(override val kind: String = "boolean", val value: Boolean) : AstNode

data class ArrayNode(override val kind: String = "array", val elements: List<AstNode>) : AstNode

data class ParseError(override val message: String, val line: Int, val column: Int) : RuntimeException("$message at $line:$column")
