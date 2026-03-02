Code.require_file("rcl_lex.ex", __DIR__)
Code.require_file("rcl_core.ex", __DIR__)
Code.require_file("rcl_convert.ex", __DIR__)

defmodule RCL do
  def parse(text), do: RCL.Core.parse(text)
  def format(text), do: text |> parse() |> RCL.Core.format_ast()
  def to_object(text), do: text |> parse() |> RCL.Core.project_ast()
  def to_yaml(text), do: text |> to_object() |> RCL.Convert.to_yaml()
  def to_toml(text), do: text |> to_object() |> RCL.Convert.to_toml()
  def to_hcl(text), do: text |> to_object() |> RCL.Convert.to_hcl()
end
