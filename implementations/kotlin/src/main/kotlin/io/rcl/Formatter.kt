package io.rcl

object Formatter {
  fun format(document: DocumentNode): String {
    if (document.rootValue is ArrayNode) return "do ${formatValue(document.rootValue)}"
    return document.blocks.joinToString("\n\n") { formatBlock(it, 0) }
  }

  private fun formatBlock(block: BlockNode, indent: Int): String {
    val pad = "  ".repeat(indent)
    val head = if (block.argument != null) "${pad}${block.name} ${q(block.argument)} do" else "${pad}${block.name} do"
    val lines = mutableListOf(head)

    for ((k, v) in block.properties) {
      if (v is ArrayNode) lines += "${pad}  $k do ${formatValue(v)} end"
      else lines += "${pad}  $k = ${formatValue(v)}"
    }

    val seen = mutableSetOf<String>()
    for (child in block.blocks.values) {
      val key = if (child.argument != null) "${child.name}:${child.argument}" else child.name
      if (seen.add(key)) lines += formatBlock(child, indent + 1)
    }
    for (child in block.namedBlocks) {
      val key = if (child.argument != null) "${child.name}:${child.argument}" else child.name
      if (seen.add(key)) lines += formatBlock(child, indent + 1)
    }

    lines += "${pad}end"
    return lines.joinToString("\n")
  }

  private fun formatValue(node: AstNode): String = when (node) {
    is StringNode -> q(node.value)
    is NumberNode -> node.value.toString()
    is BooleanNode -> if (node.value) "true" else "false"
    is ArrayNode -> "[${node.elements.joinToString(", ") { formatValue(it) }}]"
    is BlockNode -> formatAnonymousBlock(node)
    else -> throw IllegalArgumentException("unsupported value kind: ${node.kind}")
  }

  private fun formatAnonymousBlock(block: BlockNode): String {
    val parts = mutableListOf<String>()
    for ((k, v) in block.properties) parts += "$k = ${formatValue(v)}"
    for (child in block.blocks.values) parts += formatInlineBlock(child)
    for (child in block.namedBlocks) parts += formatInlineBlock(child)
    return if (parts.isEmpty()) "do end" else "do ${parts.joinToString(" ")} end"
  }

  private fun formatInlineBlock(block: BlockNode): String {
    val head = if (block.argument != null) "${block.name} ${q(block.argument)} do" else "${block.name} do"
    val parts = mutableListOf<String>()
    for ((k, v) in block.properties) parts += "$k = ${formatValue(v)}"
    for (child in block.blocks.values) parts += formatInlineBlock(child)
    for (child in block.namedBlocks) parts += formatInlineBlock(child)
    return if (parts.isEmpty()) "$head end" else "$head ${parts.joinToString(" ")} end"
  }

  private fun q(value: String?): String {
    val s = value.orEmpty()
      .replace("\\", "\\\\")
      .replace("\"", "\\\"")
      .replace("\n", "\\n")
      .replace("\t", "\\t")
    return "\"$s\""
  }
}
