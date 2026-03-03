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
    val obj = Converters.toObject(ast)
    val server = obj["server"] as Map<*, *>
    val tls = server["tls"] as Map<*, *>
    assertEquals("/etc/cert.pem", tls["cert_path"])

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
  fun namedBlockToConfigRegionsArgAndConverters() {
    val source = """
      config do
        region "us" do
          name = "My name"
        end
      end
    """.trimIndent()
    val ast = Parser.parse(source)
    val obj = Converters.toObject(ast)
    val config = obj["config"] as Map<*, *>
    val regions = config["regions"] as Map<*, *>
    val us = regions["us"] as Map<*, *>
    assertEquals("My name", us["name"])
    assertTrue(Converters.toYaml(ast).contains("regions:"))
    assertTrue(Converters.toToml(ast).contains("[config.regions.us]"))
    assertTrue(Converters.toHcl(ast).contains("regions {"))
  }

  @Test
  fun strictEdgeFailures() {
    val bad = listOf(
      "x do\n  name = value\nend",
      "x do\n  arr = [1,]\nend",
      "x do\n  a = 1\n  a = 2\nend",
      "x do\n  a = 1\n  a.b = 2\nend",
      "do [1] end",
      "x do\n  arr do [1]\n  y = 1\nend",
    )
    bad.forEach { src -> assertFailsWith<ParseError> { Parser.parse(src) } }
  }

  @Test
  fun namedArrayRootArrayAndAnonymousBlockElements() {
    val namedSrc = """
      config do
        tests do [
          do
            name = "case-1"
          end,
          "string"
        ] end
      end
    """.trimIndent()
    val namedObj = Converters.toObject(Parser.parse(namedSrc))
    val config = namedObj["config"] as Map<*, *>
    val tests = config["tests"] as List<*>
    val first = tests[0] as Map<*, *>
    assertEquals("case-1", first["name"])
    assertEquals("string", tests[1])

    val rootSrc = """
      do [
        do
          name = "root-item"
        end,
        "x"
      ]
    """.trimIndent()
    val rootObj = Converters.toObject(Parser.parse(rootSrc))
    val root = rootObj["root"] as List<*>
    val rootFirst = root[0] as Map<*, *>
    assertEquals("root-item", rootFirst["name"])
    assertEquals("x", root[1])
  }
}
