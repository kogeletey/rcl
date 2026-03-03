Code.require_file("../lib/rcl.ex", __DIR__)
ExUnit.start()

defmodule RCLTest do
  use ExUnit.Case

  defp fails(src, msg) do
    assert_raise RuntimeError, fn -> RCL.parse(src) end
    try do
      RCL.parse(src)
    rescue
      e ->
        err = Exception.message(e)
        assert String.contains?(err, msg)
        assert String.contains?(err, "line")
    end
  end

  test "ast projection converters and format" do
    src = "root do\n  widget \"blue\" do\n    title = \"My Name\"\n    enabled = true\n    nums = [1, -2, 3.5]\n  end\nend\n"
    ast = RCL.parse(src)
    assert ast.type == :document
    assert RCL.format(src) == src
    obj = RCL.to_object(src)
    assert obj["root"]["widgets"]["blue"]["title"] == "My Name"
    assert obj["root"]["widgets"]["blue"]["enabled"] == true
    assert RCL.to_yaml(src) != ""
    assert RCL.to_toml(src) != ""
    assert RCL.to_hcl(src) != ""
  end

  test "root named block and edge errors" do
    src = "env \"prod\" do\n  region \"us\" do\n    a.b = 1\n  end\nend\n"
    obj = RCL.to_object(src)
    assert obj["envs"]["prod"]["regions"]["us"]["a"]["b"] == 1

    fails("x do\n  name = value\nend\n", "invalid bare identifier value")
    fails("x do\n  arr = [1,]\nend\n", "trailing comma in array")
    fails("x do\n  a = 1\n  a = 2\nend\n", "duplicate or conflicting key path")
    fails("x do\n  a = 1\n  a.b = 2\nend\n", "duplicate or conflicting key path")
    fails("x do\n  a.b = 1\n  a = 2\nend\n", "duplicate or conflicting key path")
    fails("x do\n  s = \"bad\\q\"\nend\n", "invalid escape")
    fails("x do\n  s = \"ok\"\n", "missing end")
    fails("x do\n  a = [1,2\nend\n", "missing ]")
    fails("x do\n  s = \"bad\nend\n", "unterminated string")
    fails("x do\n  s = 'bad'\nend\n", "single-quoted string usage")
    fails("x do\n  @ = 1\nend\n", "unexpected character")
  end
end
