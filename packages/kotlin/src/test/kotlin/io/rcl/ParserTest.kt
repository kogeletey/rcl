package io.rcl

import kotlin.test.Test
import kotlin.test.assertEquals

class ParserTest {
  @Test
  fun parseScaffold() {
    val doc = Parser.parse("xray do\nend")
    assertEquals("document", doc.kind)
  }
}
