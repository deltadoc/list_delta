defmodule ListDelta.Transformation do
  alias ListDelta.{Operation}

  import Operation

  def transform(left, right, priority) do
    left_ops = ListDelta.operations(left)
    right
    |> ListDelta.operations()
    |> Enum.map(&do_transform(left_ops, &1, priority))
    |> List.flatten()
    |> wrap()
  end

  defp do_transform(left_ops, ops, priority) when is_list(ops) do
    Enum.map(ops, &do_transform(left_ops, &1, priority))
  end

  defp do_transform([%{insert: lft_idx} | remainder],
                     %{insert: idx, init: init}, :left) when idx >= lft_idx do
    do_transform(remainder, insert(idx + 1, init), :left)
  end

  defp do_transform([%{insert: lft_idx} | remainder],
                     %{insert: _} = insert, :left) do
    do_transform(remainder, [move(lft_idx, lft_idx - 1), insert], :left)
  end

  defp do_transform([%{insert: lft_idx} | remainder],
                     %{remove: idx}, :right) when idx >= lft_idx do
    do_transform(remainder, remove(idx + 1), :right)
  end

  defp do_transform([%{insert: lft_idx} | remainder],
                     %{replace: idx, init: init}, :right) when idx >= lft_idx do
    do_transform(remainder, replace(idx + 1, init), :right)
  end

  defp do_transform([%{insert: lft_idx} | remainder],
                     %{move: idx, to: to_idx}, :right) when idx >= lft_idx do
    do_transform(remainder, move(idx + 1, to_idx + 1), :right)
  end

  defp do_transform([%{remove: lft_idx} | remainder],
                     %{insert: idx, init: init}, priority) when idx > lft_idx do
    do_transform(remainder, insert(idx - 1, init), priority)
  end

  defp do_transform([_ | remainder], op, priority) do
    do_transform(remainder, op, priority)
  end

  defp do_transform([], op, _priority) do
    op
  end

  defp wrap(ops), do: %ListDelta{ops: List.wrap(ops)}
end
