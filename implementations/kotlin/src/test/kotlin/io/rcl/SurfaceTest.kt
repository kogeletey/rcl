package io.rcl

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SurfaceTest {
  @Test
  fun coreSurfaceParsesAndProjects() {
    val src = """
      root do
        service "api" do
          title = "My Name"
        end
      end
    """.trimIndent()
    val ast = io.rcl.core.RCL.parse(src)
    assertEquals("document", ast.kind)
    val obj = io.rcl.core.RCL.toObject(ast)
    val root = obj["root"] as Map<*, *>
    val services = root["services"] as Map<*, *>
    val api = services["api"] as Map<*, *>
    assertEquals("My Name", api["title"])

    val methods = io.rcl.core.RCL::class.java.methods.map { it.name }.toSet()
    assertTrue("format" !in methods)
    assertTrue("toYaml" !in methods)
    assertTrue("toToml" !in methods)
    assertTrue("toHcl" !in methods)
  }

  @Test
  fun extendedSurfaceIncludesFormattingAndExports() {
    val src = """
      root do
        service "api" do
          title = "My Name"
        end
      end
    """.trimIndent()
    val ast = RCL.parse(src)
    assertTrue(RCL.format(ast).contains("root do"))
    assertTrue(RCL.toYaml(ast).contains("services:"))
    assertTrue(RCL.toToml(ast).contains("[root.services.api]"))
    assertTrue(RCL.toHcl(ast).contains("services {"))
  }
}
