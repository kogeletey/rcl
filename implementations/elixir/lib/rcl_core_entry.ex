Code.require_file("rcl_lex.ex", __DIR__)
Code.require_file("rcl_core.ex", __DIR__)

defmodule RCLCore do
  def parse(text), do: RCL.Core.parse(text)
  def to_object(text), do: text |> parse() |> RCL.Core.project_ast()
end
