package io.rcl

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class ParserTest {
  @Test
  fun parseAndFormatFullSpec() {
    val source = """
      # comment
      server do
        host = "localhost"
        port = 8080
        ratio = 3.14
        negative = -42
        enabled = true
        names = ["a", "b", 1, false]
        tls.cert_path = "/etc/cert.pem"
        region "us-east" do
          replicas = 2
        end
      end
    """.trimIndent()

    val ast = Parser.parse(source)
    assertEquals("document", ast.kind)
    assertEquals("server", ast.blocks.first().name)
    assertTrue(ast.blocks.first().properties.containsKey("tls.cert_path"))

    val out = Formatter.format(ast)
    val reparsed = Parser.parse(out)
    assertEquals(ast, reparsed)
  }

  @Test
  fun parseErrorContainsPosition() {
    val ex = assertFailsWith<ParseError> { Parser.parse("x do\n  arr = [1,2\nend") }
    assertTrue(ex.line > 0)
    assertTrue(ex.column > 0)
  }

  @Test
  fun namedBlockToRegionArgAndConverters() {
    val source = """
      config do
        region "us" do
          name = "My name"
        end
      end
    """.trimIndent()
    val ast = Parser.parse(source)
    val obj = Converters.toObject(ast)
    val region = obj["region"] as Map<*, *>
    val us = region["us"] as Map<*, *>
    assertEquals("My name", us["name"])
    assertTrue(Converters.toYaml(ast).contains("region:"))
    assertTrue(Converters.toToml(ast).contains("[region.us]"))
    assertTrue(Converters.toHcl(ast).contains("region {"))
  }
}
