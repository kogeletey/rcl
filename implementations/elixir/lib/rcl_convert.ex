defmodule RCL.Convert do
  def to_yaml(m), do: yaml_map(m, 0)

  def to_toml(m) do
    lines = toml_table(m, [])
    if lines == [], do: "", else: Enum.join(lines, "\n") <> "\n"
  end

  def to_hcl(m) do
    if m == %{}, do: "{}\n", else: Enum.map_join(entries(m), "", fn {k, v} -> hcl_key(k) <> " = " <> hcl_val(v, 0) <> "\n" end)
  end

  defp yaml_map(m, n) do
    if m == %{} do
      String.duplicate(" ", n) <> "{}\n"
    else
      Enum.map_join(entries(m), "", fn {k, v} ->
        i = String.duplicate(" ", n)
        if is_map(v), do: i <> yaml_key(k) <> ":\n" <> yaml_map(v, n + 2), else: i <> yaml_key(k) <> ": " <> scalar(v) <> "\n"
      end)
    end
  end

  defp toml_table(m, path) do
    header = if path == [], do: [], else: ["[" <> Enum.map_join(path, ".", &toml_key/1) <> "]"]
    {maps, vals} = Enum.reduce(entries(m), {[], []}, fn {k, v}, {ms, vs} -> if is_map(v), do: {[{k, v} | ms], vs}, else: {ms, [toml_key(k) <> " = " <> scalar(v) | vs]} end)
    base = header ++ Enum.reverse(vals)
    Enum.reverse(maps)
    |> Enum.reduce(base, fn {k, v}, acc ->
      t = toml_table(v, path ++ [k])
      if acc == [], do: t, else: acc ++ [""] ++ t
    end)
  end

  defp hcl_val(v, n) do
    cond do
      is_map(v) and map_size(v) == 0 -> "{}"
      is_map(v) ->
        i = String.duplicate(" ", n)
        "{\n" <> Enum.map_join(entries(v), "", fn {k, x} -> i <> "  " <> hcl_key(k) <> " = " <> hcl_val(x, n + 2) <> "\n" end) <> i <> "}"
      true -> scalar(v)
    end
  end

  defp scalar(v) when is_binary(v), do: "\"" <> esc(v) <> "\""
  defp scalar(v) when is_boolean(v), do: if(v, do: "true", else: "false")
  defp scalar(v) when is_list(v), do: "[" <> Enum.map_join(v, ", ", &scalar/1) <> "]"
  defp scalar(v), do: to_string(v)

  defp entries(m), do: Enum.sort_by(m, fn {k, _} -> k end)
  defp bare?(k), do: Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*$/, k)
  defp toml_key(k), do: if(bare?(k), do: k, else: "\"" <> esc(k) <> "\"")
  defp yaml_key(k), do: if(bare?(k), do: k, else: "\"" <> esc(k) <> "\"")
  defp hcl_key(k), do: if(bare?(k), do: k, else: "\"" <> esc(k) <> "\"")
  defp esc(s), do: s |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"") |> String.replace("\n", "\\n") |> String.replace("\t", "\\t")
end
