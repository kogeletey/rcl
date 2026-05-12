package io.rcl

object RCL {
  fun parse(text: String): DocumentNode = Parser.parse(text)
  fun format(text: String): String = format(parse(text))
  fun format(document: DocumentNode): String = Formatter.format(document)
  fun toObject(text: String): Map<String, Any?> = toObject(parse(text))
  fun toObject(document: DocumentNode): Map<String, Any?> = Converters.toObject(document)
  fun toYaml(text: String): String = toYaml(parse(text))
  fun toYaml(document: DocumentNode): String = Converters.toYaml(document)
  fun toToml(text: String): String = toToml(parse(text))
  fun toToml(document: DocumentNode): String = Converters.toToml(document)
  fun toHcl(text: String): String = toHcl(parse(text))
  fun toHcl(document: DocumentNode): String = Converters.toHcl(document)
}
