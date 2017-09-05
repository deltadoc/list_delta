defmodule ListDelta.Composition do
  alias ListDelta.{Index, Operation, ItemDelta}

  def compose(first, second) do
    second
    |> List.foldl(Index.from_operations(first), &do_compose/2)
    |> Index.to_operations()
  end

  defp do_compose(:noop, ops_index), do: ops_index
  defp do_compose(new_op, ops_index) do
    existing_op = Enum.at(ops_index, Operation.index(new_op), :noop)
    do_compose(existing_op, new_op, ops_index)
  end

  defp do_compose(%{insert: _},
                  %{remove: idx}, ops_index) do
    Index.delete_at(ops_index, idx)
  end
  defp do_compose(%{insert: idx},
                  %{replace: _, init: init}, ops_index) do
    Index.replace_at(ops_index, idx, Operation.insert(idx, init))
  end
  defp do_compose(%{insert: idx, init: init},
                  %{change: _, delta: delta}, ops_index) do
    new_init = ItemDelta.compose(init, delta)
    Index.replace_at(ops_index, idx, Operation.insert(idx, new_init))
  end

  defp do_compose(%{remove: idx},
                  %{insert: _, init: init}, ops_index) do
    Index.replace_at(ops_index, idx, Operation.replace(idx, init))
  end
  defp do_compose(%{remove: _},
                  %{change: _}, ops_index) do
    ops_index
  end

  defp do_compose(%{replace: idx, init: init},
                  %{change: _, delta: delta}, ops_index) do
    new_init = ItemDelta.compose(init, delta)
    Index.replace_at(ops_index, idx, Operation.replace(idx, new_init))
  end

  defp do_compose(_left, right, ops_index) do
    Index.add(ops_index, right)
  end
end
