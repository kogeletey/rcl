package io.rcl

object Converters {
  fun toObject(document: DocumentNode): Map<String, Any?> {
    if (document.blocks.size == 1) return blockToMap(document.blocks.first())
    return document.blocks.associate { it.name to blockToMap(it) }
  }

  fun toYaml(document: DocumentNode): String = emitYaml(toObject(document), 0)
  fun toToml(document: DocumentNode): String = emitToml(toObject(document))
  fun toHcl(document: DocumentNode): String = emitHcl(toObject(document), 0)

  private fun blockToMap(block: BlockNode): MutableMap<String, Any?> {
    val result = linkedMapOf<String, Any?>()
    block.properties.forEach { (k, v) -> result[k] = nodeToAny(v) }

    val children = uniqueChildren(block)
    children.filter { it.argument == null }.forEach { child ->
      val childMap = blockToMap(child)
      val existing = result[child.name] as? Map<String, Any?>
      if (existing != null) childMap.putAll(existing)
      result[child.name] = childMap
    }
    children.filter { it.argument != null }.forEach { child ->
      val parent = (result[child.name] as? MutableMap<String, Any?>) ?: linkedMapOf()
      parent[child.argument!!] = blockToMap(child)
      result[child.name] = parent
    }
    return result
  }

  private fun uniqueChildren(block: BlockNode): List<BlockNode> {
    val out = mutableListOf<BlockNode>()
    val seen = mutableSetOf<String>()
    val fromMap = block.blocks.values.toList().sortedBy { (it.argument?.let { a -> "${it.name}:$a" } ?: it.name) }
    (fromMap + block.namedBlocks).forEach { child ->
      val key = child.argument?.let { a -> "${child.name}:$a" } ?: child.name
      if (seen.add(key)) out += child
    }
    return out
  }

  private fun nodeToAny(node: AstNode): Any? = when (node) {
    is StringNode -> node.value
    is NumberNode -> node.value
    is BooleanNode -> node.value
    is ArrayNode -> node.elements.map { nodeToAny(it) }
    else -> null
  }

  private fun emitYaml(v: Any?, indent: Int): String {
    val pad = "  ".repeat(indent)
    return when (v) {
      is Map<*, *> -> v.keys.map { it.toString() }.sorted().joinToString("\n") { k ->
        val item = v[k]
        if (item is Map<*, *> || item is List<*>) "$pad$k:\n${emitYaml(item, indent + 1)}"
        else "$pad$k: ${scalar(item)}"
      }
      is List<*> -> v.joinToString("\n") { item ->
        if (item is Map<*, *> || item is List<*>) "$pad-\n${emitYaml(item, indent + 1)}"
        else "$pad- ${scalar(item)}"
      }
      else -> "$pad${scalar(v)}"
    }
  }

  private fun emitToml(root: Map<String, Any?>): String {
    val out = mutableListOf<String>()
    fun walk(obj: Map<String, Any?>, prefix: String?) {
      obj.keys.sorted().forEach { k -> if (obj[k] !is Map<*, *>) out += "$k = ${scalar(obj[k])}" }
      obj.keys.sorted().forEach { k ->
        val child = obj[k] as? Map<String, Any?> ?: return@forEach
        val sec = if (prefix == null) k else "$prefix.$k"
        if (out.isNotEmpty()) out += ""
        out += "[$sec]"
        walk(child, sec)
      }
    }
    walk(root, null)
    return out.joinToString("\n")
  }

  private fun emitHcl(v: Any?, indent: Int): String {
    val pad = "  ".repeat(indent)
    val obj = v as? Map<String, Any?> ?: return "$pad${scalar(v)}"
    return obj.keys.sorted().joinToString("\n") { k ->
      val item = obj[k]
      if (item is Map<*, *>) "$pad$k {\n${emitHcl(item, indent + 1)}\n$pad}"
      else "$pad$k = ${scalar(item)}"
    }
  }

  private fun scalar(v: Any?): String = when (v) {
    is String -> "\"${v.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\t", "\\t")}\""
    is Boolean -> if (v) "true" else "false"
    is Number -> v.toString()
    is List<*> -> "[${v.joinToString(", ") { scalar(it) }}]"
    else -> "{}"
  }
}
