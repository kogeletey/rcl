package io.rcl

data class DocumentNode(
  val kind: String = "document",
  val blocks: List<Map<String, Any?>> = emptyList(),
)

object Parser {
  fun parse(text: String): DocumentNode = DocumentNode()
  fun format(document: DocumentNode): String = ""
}
