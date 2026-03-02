require "minitest/autorun"
require_relative "../lib/rcl"

class ParserTest < Minitest::Test
  def test_parse_and_format
    source = "xray do\n  port = 8080\n  enabled = true\nend"
    ast = RCL.parse(source)

    assert_equal "document", ast["kind"]
    assert_equal "xray", ast["blocks"][0]["name"]

    out = RCL.format(ast)
    assert_equal source, out
  end
end
