defmodule ListDelta.Index do
  alias ListDelta.Operation

  def new, do: []

  def from_operations(ops) do
    List.foldl(ops, new(), &add(&2, &1))
  end

  def add(ops_index, %{insert: idx} = op) do
    ops_index
    |> insert_at_index(idx, op)
    |> reindex_ops()
  end
  def add(ops_index, %{remove: idx} = op) do
    ops_index
    |> List.delete_at(idx)
    |> replace_at_index(idx, op)
    |> reindex_ops()
  end
  def add(ops_index, op) do
    ops_index
    |> replace_at_index(Operation.index(op), op)
  end

  def replace_at(ops_index, idx, op), do: List.replace_at(ops_index, idx, op)
  def delete_at(ops_index, idx), do: List.delete_at(ops_index, idx)

  def to_operations(ops_index) do
    ops_index
    |> List.foldl([], &prepend_op(&2, &1))
    |> Enum.reverse()
    |> Enum.filter(&(&1 != :noop))
  end

  defp insert_at_index(list, idx, val) do
    list
    |> ensure_length(idx)
    |> List.insert_at(idx, val)
  end

  defp replace_at_index(list, idx, val) do
    list
    |> ensure_length(idx + 1)
    |> List.replace_at(idx, val)
  end

  defp reindex_ops(ops_index) do
    ops_index
    |> Enum.with_index()
    |> Enum.map(&reindex_op/1)
  end

  defp reindex_op({:noop, _actual_idx}), do: :noop
  defp reindex_op({op, actual_idx}), do: Operation.change_index(op, actual_idx)

  defp prepend_op([%{insert: prev_idx} = prev_ins | remainder],
                   %{insert: _, init: init}) do
    [prev_ins | prepend_op(remainder, Operation.insert(prev_idx, init))]
  end
  defp prepend_op([], %{insert: _, init: init}) do
    [Operation.insert(0, init)]
  end
  defp prepend_op(ops, op), do: [op | ops]

  defp ensure_length(list, idx) when length(list) >= idx, do: list
  defp ensure_length(list, idx), do: ensure_length(list ++ [:noop], idx)
end
