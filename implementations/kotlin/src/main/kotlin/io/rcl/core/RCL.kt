package io.rcl.core

import io.rcl.DocumentNode
import io.rcl.Parser
import io.rcl.Converters

object RCL {
  fun parse(text: String): DocumentNode = Parser.parse(text)
  fun toObject(text: String): Map<String, Any?> = toObject(parse(text))
  fun toObject(document: DocumentNode): Map<String, Any?> = Converters.toObject(document)
}
