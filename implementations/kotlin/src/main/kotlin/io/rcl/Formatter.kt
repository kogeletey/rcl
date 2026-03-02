package io.rcl

object Formatter {
  fun format(document: DocumentNode): String = document.blocks.joinToString("\n\n") { formatBlock(it, 0) }

  private fun formatBlock(block: BlockNode, indent: Int): String {
    val pad = "  ".repeat(indent)
    val head = if (block.argument != null) "${pad}${block.name} ${q(block.argument)} do" else "${pad}${block.name} do"
    val lines = mutableListOf(head)

    for ((k, v) in block.properties) lines += "${pad}  $k = ${formatValue(v)}"

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
    else -> throw IllegalArgumentException("unsupported value kind: ${node.kind}")
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
