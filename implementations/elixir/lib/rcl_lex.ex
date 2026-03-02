defmodule RCL.Core.Lex do
  def lex(src), do: scan(src, 0, 1, 1, []) |> Enum.reverse() ++ [{:eof, nil, line(src), 1}]

  defp scan(src, i, l, c, acc) when i >= byte_size(src), do: acc
  defp scan(src, i, l, c, acc) do
    ch = :binary.at(src, i)
    cond do
      ws?(ch) -> {ni, nl, nc} = adv(src, i, l, c); scan(src, ni, nl, nc, acc)
      ch == ?# -> {ni, nl, nc} = skip_comment(src, i, l, c); scan(src, ni, nl, nc, acc)
      ch == ?' -> fail("single-quoted string usage", l, c)
      ch == ?/ and i + 1 < byte_size(src) and :binary.at(src, i + 1) == ?/ -> fail("unexpected character", l, c)
      id_start?(ch) -> {tok, ni, nl, nc} = lex_id(src, i, l, c); scan(src, ni, nl, nc, [tok | acc])
      num_start?(src, i, ch) -> {tok, ni, nl, nc} = lex_num(src, i, l, c); scan(src, ni, nl, nc, [tok | acc])
      ch == ?" -> {tok, ni, nl, nc} = lex_str(src, i, l, c); scan(src, ni, nl, nc, [tok | acc])
      ch in [?=, ?., ?[, ?], ?,] ->
        t = %{?= => :eq, ?. => :dot, ?[ => :lbr, ?] => :rbr, ?, => :comma}[ch]
        {ni, nl, nc} = adv(src, i, l, c)
        scan(src, ni, nl, nc, [{t, <<ch>>, l, c} | acc])
      true -> fail("unexpected character", l, c)
    end
  end

  defp ws?(c), do: c in [9, 10, 13, 32]
  defp id_start?(c), do: (c >= ?a and c <= ?z) or (c >= ?A and c <= ?Z) or c == ?_
  defp id?(c), do: id_start?(c) or (c >= ?0 and c <= ?9)
  defp num_start?(src, i, c), do: (c >= ?0 and c <= ?9) or (c == ?- and i + 1 < byte_size(src) and :binary.at(src, i + 1) in ?0..?9)
  defp line(src), do: String.split(src, "\n") |> length()
  defp adv(src, i, l, c), do: if(:binary.at(src, i) == 10, do: {i + 1, l + 1, 1}, else: {i + 1, l, c + 1})
  defp skip_comment(src, i, l, c), do: if(i >= byte_size(src) or :binary.at(src, i) == 10, do: {i, l, c}, else: skip_comment(src, i + 1, l, c + 1))

  defp lex_id(src, i, l, c), do: lex_id(src, i, l, c, "")
  defp lex_id(src, i, l, c, acc) do
    if i < byte_size(src) and id?(:binary.at(src, i)), do: lex_id(src, i + 1, l, c + 1, acc <> <<:binary.at(src, i)>>), else: id_tok(acc, i, l, c)
  end
  defp id_tok("do", i, l, c), do: {{:do, "do", l, c}, i, l, c + 2}
  defp id_tok("end", i, l, c), do: {{:end, "end", l, c}, i, l, c + 3}
  defp id_tok("true", i, l, c), do: {{:bool, true, l, c}, i, l, c + 4}
  defp id_tok("false", i, l, c), do: {{:bool, false, l, c}, i, l, c + 5}
  defp id_tok(v, i, l, c), do: {{:id, v, l, c}, i, l, c + byte_size(v)}

  defp lex_num(src, i, l, c), do: lex_num(src, i, l, c, "", false)
  defp lex_num(src, i, l, c, acc, dot) do
    cond do
      i < byte_size(src) and :binary.at(src, i) in ?0..?9 -> lex_num(src, i + 1, l, c + 1, acc <> <<:binary.at(src, i)>>, dot)
      i < byte_size(src) and :binary.at(src, i) == ?- and acc == "" -> lex_num(src, i + 1, l, c + 1, "-", dot)
      i < byte_size(src) and :binary.at(src, i) == ?. and not dot and i + 1 < byte_size(src) and :binary.at(src, i + 1) in ?0..?9 -> lex_num(src, i + 1, l, c + 1, acc <> ".", true)
      true ->
        n = if String.contains?(acc, "."), do: String.to_float(acc), else: String.to_integer(acc)
        {{:number, {n, acc}, l, c - byte_size(acc)}, i, l, c}
    end
  end

  defp lex_str(src, i, l, c), do: lex_str(src, i + 1, l, c + 1, "", l, c)
  defp lex_str(src, i, l, c, acc, sl, sc) do
    cond do
      i >= byte_size(src) -> fail("unterminated string", sl, sc)
      :binary.at(src, i) == ?" -> {{:string, acc, sl, sc}, i + 1, l, c + 1}
      :binary.at(src, i) == 10 -> fail("unterminated string", sl, sc)
      :binary.at(src, i) == ?\\ -> esc_seq(src, i + 1, l, c + 1, acc, sl, sc)
      true -> lex_str(src, i + 1, l, c + 1, acc <> <<:binary.at(src, i)>>, sl, sc)
    end
  end
  defp esc_seq(src, i, l, c, acc, sl, sc) do
    if i >= byte_size(src), do: fail("unterminated string", sl, sc)
    case :binary.at(src, i) do
      ?" -> lex_str(src, i + 1, l, c + 1, acc <> "\"", sl, sc)
      ?\\ -> lex_str(src, i + 1, l, c + 1, acc <> "\\", sl, sc)
      ?n -> lex_str(src, i + 1, l, c + 1, acc <> "\n", sl, sc)
      ?t -> lex_str(src, i + 1, l, c + 1, acc <> "\t", sl, sc)
      _ -> fail("invalid escape", l, c)
    end
  end

  defp fail(m, l, c), do: raise("line #{l}, column #{c}: #{m}")
end
