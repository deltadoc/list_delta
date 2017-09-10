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

  defp do_transform([%{insert: _} | remainder],
                     %{insert: _} = insert, :right) do
    do_transform(remainder, insert, :right)
  end

  defp do_transform([%{insert: left_idx} | remainder],
                     %{insert: idx, init: init}, :left) when idx >= left_idx do
    do_transform(remainder, insert(idx + 1, init), :left)
  end

  defp do_transform([%{insert: left_idx} | remainder],
                     %{insert: _} = insert, :left) do
    do_transform(remainder, [move(left_idx, left_idx - 1), insert], :left)
  end

  defp do_transform([%{insert: left_idx} | remainder],
                     %{remove: idx}, :right) when idx >= left_idx do
    do_transform(remainder, remove(idx + 1), :right)
  end

  defp do_transform([%{insert: left_idx} | remainder],
                     %{replace: idx, init: init}, :right) when idx >= left_idx do
    do_transform(remainder, replace(idx + 1, init), :right)
  end

  defp do_transform([%{remove: left_idx} | remainder],
                     %{insert: idx, init: init}, priority) when idx > left_idx do
    do_transform(remainder, insert(idx - 1, init), priority)
  end

  defp do_transform(_left_ops, op, _priority) do
    op
  end

  defp wrap(ops), do: %ListDelta{ops: List.wrap(ops)}
end
