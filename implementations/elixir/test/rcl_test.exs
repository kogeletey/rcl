Mix.install([{:jason, "~> 1.4"}])
Code.require_file("../lib/rcl.ex", __DIR__)
ExUnit.start()

defmodule RCLTest do
  use ExUnit.Case
  test "spec + edge" do
    src = "config do\n  region \"us\" do\n    name = \"My Name\"\n  end\nend\n"
    assert RCL.to_object(src)["config"]["regions"]["us"]["name"] == "My Name"
    assert String.contains?(RCL.to_toml(src), "[config.regions.us]")
    assert_raise RuntimeError, fn -> RCL.parse("x do\n  name = value\nend\n") end
  end
end
