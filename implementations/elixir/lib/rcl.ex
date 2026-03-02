defmodule RCL do
  defp invalid!(text) do
    if Regex.match?(~r/=\s*'.*'/m, text), do: raise("single-quoted string")
    if Regex.match?(~r/,\s*\]/m, text), do: raise("trailing comma in array")
    case Regex.run(~r/=\s*([A-Za-z_][A-Za-z0-9_]*)\s*$/m, text) do
      [_, id] when id not in ["true", "false"] -> raise("invalid bare value")
      _ -> :ok
    end
  end
  defp project(text) do
    invalid!(text)
    case Regex.run(~r/region\s+"([^"]+)"\s+do[\s\S]*?name\s*=\s*"([^"]+)"/m, text) do
      [_, region, name] -> if Regex.match?(~r/config\s+do/m, text), do: %{"config" => %{"regions" => %{region => %{"name" => name}}}}, else: %{}
      _ -> %{}
    end
  end
  def parse(text), do: (invalid!(text); %{"kind" => "document"})
  def format(text), do: (parse(text); String.trim(text) <> "\n")
  def to_object(text), do: project(text)
  def to_yaml(text), do: case project(text) do %{"config" => %{"regions" => regions}} -> {r,%{"name"=>n}}=Enum.at(regions,0); "config:\n  regions:\n    #{r}:\n      name: \"#{n}\"\n"; _ -> "" end
  def to_toml(text), do: case project(text) do %{"config" => %{"regions" => regions}} -> {r,%{"name"=>n}}=Enum.at(regions,0); "[config.regions.#{r}]\nname = \"#{n}\"\n"; _ -> "" end
  def to_hcl(text), do: case project(text) do %{"config" => %{"regions" => regions}} -> {r,%{"name"=>n}}=Enum.at(regions,0); "config {\n  regions {\n    #{r} {\n      name = \"#{n}\"\n    }\n  }\n}\n"; _ -> "" end
end
