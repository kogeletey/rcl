defmodule RCL.Core do
  def parse(src), do: src |> RCL.Core.Lex.lex() |> program(0)

  def format_ast(%{type: :document, blocks: blocks}), do: Enum.map_join(blocks, "", &fmt_block(&1, 0))

  def project_ast(%{type: :document, blocks: blocks}), do: Enum.reduce(blocks, %{}, &merge_block/2)

  defp program(ts, p) do
    {bs, np} = blocks(ts, p, [])
    expect(ts, np, :eof)
    %{type: :document, blocks: Enum.reverse(bs)}
  end

  defp blocks(ts, p, acc) do
    case token(ts, p) do
      {:eof, _, _, _} -> {acc, p}
      _ -> {b, np} = block(ts, p); blocks(ts, np, [b | acc])
    end
  end

  defp block(ts, p) do
    {_, name, _, _} = expect(ts, p, :id)
    {arg, p1} = case token(ts, p + 1) do {:string, v, _, _} -> {v, p + 2}; _ -> {nil, p + 1} end
    expect(ts, p1, :do)
    {stmts, p2, _keys} = statements(ts, p1 + 1, [], [])
    expect(ts, p2, :end)
    {%{type: :block, name: name, arg: arg, statements: stmts}, p2 + 1}
  end

  defp statements(ts, p, keys, acc) do
    case token(ts, p) do
      {:end, _, _, _} -> {Enum.reverse(acc), p, keys}
      {:eof, _, l, c} -> fail("missing end", l, c)
      _ -> {st, np, nk} = statement(ts, p, keys); statements(ts, np, nk, [st | acc])
    end
  end

  defp statement(ts, p, keys) do
    {_, name, l, c} = expect(ts, p, :id)
    case token(ts, p + 1) do
      {:do, _, _, _} -> child(ts, p + 1, name, nil, keys)
      {:string, arg, _, _} -> child(ts, p + 2, name, arg, keys)
      _ ->
        {path, p1} = key_path(ts, p + 1, [name])
        expect(ts, p1, :eq)
        check_path(keys, path, l, c)
        {val, p2} = value(ts, p1 + 1)
        {%{type: :property, key: path, value: val}, p2, [path | keys]}
    end
  end

  defp child(ts, p, name, arg, keys) do
    expect(ts, p, :do)
    {stmts, p1, _} = statements(ts, p + 1, [], [])
    expect(ts, p1, :end)
    {%{type: :block, name: name, arg: arg, statements: stmts}, p1 + 1, keys}
  end

  defp key_path(ts, p, acc) do
    case token(ts, p) do
      {:dot, _, _, _} -> {_, id, _, _} = expect(ts, p + 1, :id); key_path(ts, p + 2, acc ++ [id])
      _ -> {acc, p}
    end
  end

  defp value(ts, p) do
    case token(ts, p) do
      {:string, v, _, _} -> {%{type: :string, value: v}, p + 1}
      {:number, {n, raw}, _, _} -> {%{type: :number, value: n, raw: raw}, p + 1}
      {:bool, v, _, _} -> {%{type: :boolean, value: v}, p + 1}
      {:lbr, _, l, c} -> array(ts, p + 1, [], l, c)
      {:id, _, l, c} -> fail("invalid bare identifier value", l, c)
      {_, _, l, c} -> fail("unexpected token", l, c)
    end
  end

  defp array(ts, p, acc, l, c) do
    case token(ts, p) do
      {:rbr, _, _, _} -> {%{type: :array, items: Enum.reverse(acc)}, p + 1}
      _ ->
        {v, p1} = value(ts, p)
        case token(ts, p1) do
          {:comma, _, _, _} -> case token(ts, p1 + 1) do {:rbr, _, rl, rc} -> fail("trailing comma in array", rl, rc); _ -> array(ts, p1 + 1, [v | acc], l, c) end
          {:rbr, _, _, _} -> {%{type: :array, items: Enum.reverse([v | acc])}, p1 + 1}
          _ -> fail("missing ]", l, c)
        end
    end
  end

  defp merge_block(b, out) do
    obj = project_block(b)
    if b.arg == nil, do: merge_at(out, b.name, obj), else: merge_named(out, base(b.name), b.arg, obj)
  end

  defp project_block(%{statements: ss}), do: Enum.reduce(ss, %{}, &project_stmt/2)
  defp project_stmt(%{type: :property, key: k, value: v}, out), do: put_path(out, k, val(v))
  defp project_stmt(%{type: :block, name: n, arg: nil} = b, out), do: merge_at(out, n, project_block(b))
  defp project_stmt(%{type: :block, name: n, arg: a} = b, out), do: merge_named(out, base(n), a, project_block(b))

  defp fmt_block(b, n) do
    i = String.duplicate(" ", n)
    h = i <> b.name <> if(b.arg == nil, do: "", else: " \"" <> esc(b.arg) <> "\"") <> " do\n"
    m = Enum.map_join(b.statements, "", fn s -> if s.type == :property, do: i <> "  " <> Enum.join(s.key, ".") <> " = " <> fmt_val(s.value) <> "\n", else: fmt_block(s, n + 2) end)
    h <> m <> i <> "end\n"
  end

  defp fmt_val(v) do
    case v.type do
      :string -> "\"" <> esc(v.value) <> "\""
      :number -> v.raw
      :boolean -> if(v.value, do: "true", else: "false")
      :array -> "[" <> Enum.map_join(v.items, ", ", &fmt_val/1) <> "]"
    end
  end

  defp val(v), do: if(v.type == :array, do: Enum.map(v.items, &val/1), else: v.value)
  defp put_path(m, [k], v), do: Map.put(m, k, v)
  defp put_path(m, [k | rest], v), do: Map.put(m, k, put_path(Map.get(m, k, %{}), rest, v))
  defp merge_named(m, b, a, v), do: Map.put(m, b, merge_at(Map.get(m, b, %{}), a, v))
  defp merge_at(m, k, v), do: Map.put(m, k, deep_merge(Map.get(m, k, %{}), v))
  defp deep_merge(a, b), do: Map.merge(a, b, fn _, x, y -> if(is_map(x) and is_map(y), do: deep_merge(x, y), else: y) end)
  defp base(n), do: if(String.ends_with?(n, "s"), do: n, else: n <> "s")

  defp check_path(keys, path, l, c) do
    if Enum.any?(keys, fn k -> k == path or prefix?(k, path) or prefix?(path, k) end), do: fail("duplicate or conflicting key path", l, c)
  end

  defp prefix?(a, b), do: length(a) < length(b) and Enum.zip(a, b) |> Enum.all?(fn {x, y} -> x == y end)
  defp expect(ts, p, t), do: case token(ts, p) do {^t, v, l, c} -> {t, v, l, c}; {_, _, l, c} -> fail("unexpected token", l, c) end
  defp token(ts, p), do: Enum.at(ts, p)
  defp fail(m, l, c), do: raise("line #{l}, column #{c}: #{m}")

  defp esc(s), do: s |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"") |> String.replace("\n", "\\n") |> String.replace("\t", "\\t")
end
