package io.rcl

object Converters {
  fun toObject(document: DocumentNode): Map<String, Any?> {
    if (document.blocks.isEmpty()) return emptyMap()
    val out = linkedMapOf<String, Any?>()
    document.blocks.forEach { root ->
      if (root.argument != null) out[namedBase(root.name)] = mapOf(root.argument!! to blockToMap(root))
      else out[root.name] = blockToMap(root)
    }
    return out
  }

  fun toYaml(document: DocumentNode): String = emitYaml(toObject(document), 0)
  fun toToml(document: DocumentNode): String = emitToml(toObject(document))
  fun toHcl(document: DocumentNode): String = emitHcl(toObject(document), 0)

  private fun blockToMap(block: BlockNode): MutableMap<String, Any?> {
    val result = linkedMapOf<String, Any?>()
    block.properties.forEach { (k, v) -> insertPath(result, k, nodeToAny(v)) }

    val children = uniqueChildren(block)
    children.filter { it.argument == null }.forEach { child ->
      val childMap = blockToMap(child)
      val existing = result[child.name] as? Map<String, Any?>
      if (existing != null) childMap.putAll(existing)
      result[child.name] = childMap
    }
    children.filter { it.argument != null }.forEach { child ->
      val base = namedBase(child.name)
      val parent = (result[base] as? MutableMap<String, Any?>) ?: linkedMapOf()
      parent[child.argument!!] = blockToMap(child)
      result[base] = parent
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

  private fun insertPath(target: MutableMap<String, Any?>, key: String, value: Any?) {
    val parts = key.split(".")
    if (parts.size == 1) {
      if (target.containsKey(key)) throw IllegalArgumentException("duplicate key")
      target[key] = value
      return
    }
    val head = parts.first()
    val existing = target[head]
    if (existing != null && existing !is MutableMap<*, *> && existing !is Map<*, *>) {
      throw IllegalArgumentException("key conflict")
    }
    val branch = (existing as? MutableMap<String, Any?>) ?: (existing as? Map<String, Any?>)?.toMutableMap() ?: linkedMapOf()
    insertPath(branch, parts.drop(1).joinToString("."), value)
    target[head] = branch
  }

  private fun namedBase(name: String): String = if (name.endsWith("s")) name else "${name}s"
}
