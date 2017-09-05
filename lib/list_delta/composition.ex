defmodule ListDelta.Composition do
  alias ListDelta.{Index, Operation, ItemDelta}

  def compose(first, second) do
    second
    |> List.foldl(Index.new(first), &do_compose/2)
    |> Index.to_operations()
  end

  defp do_compose(:noop, ops_index), do: ops_index

  defp do_compose(%{insert: idx, init: init} = ins, ops_index) do
    case Enum.at(ops_index, idx, :noop) do
      %{remove: _} ->
        Index.replace_at(ops_index, idx, Operation.replace(idx, init))
      _ ->
        Index.add(ops_index, ins)
    end
  end

  defp do_compose(%{replace: idx, init: init} = rem, ops_index) do
    case Enum.at(ops_index, idx, :noop) do
      %{insert: prev_idx} ->
        Index.replace_at(ops_index, idx, Operation.insert(prev_idx, init))
      _ ->
        Index.add(ops_index, rem)
    end
  end

  defp do_compose(%{remove: idx} = rem, ops_index) do
    case Enum.at(ops_index, idx, :noop) do
      %{insert: _} -> Index.replace_at(ops_index, idx)
      _ -> Index.add(ops_index, rem)
    end
  end

  defp do_compose(%{change: idx, delta: delta} = chg, ops_index) do
    case Enum.at(ops_index, idx, :noop) do
      %{insert: prev_idx, init: init} ->
        new_init = ItemDelta.compose(init, delta)
        Index.replace_at(ops_index, idx, Operation.insert(prev_idx, new_init))
      %{replace: prev_idx, init: init} ->
        new_init = ItemDelta.compose(init, delta)
        Index.replace_at(ops_index, idx, Operation.replace(prev_idx, new_init))
      %{change: prev_idx, delta: prev_delta} ->
        new_delta = ItemDelta.compose(prev_delta, delta)
        Index.replace_at(ops_index, idx, Operation.change(prev_idx, new_delta))
      _ ->
        Index.add(ops_index, chg)
    end
  end

  defp do_compose(op, ops_index) do
    Index.add(ops_index, op)
  end
end
