defmodule ListDelta.OperationsIndexer do
  alias ListDelta.Operation

  def index_operations(ops, offset \\ 0) do
    ops
    |> Enum.with_index(offset)
    |> List.foldl([], &index_op/2)
  end

  def unindex_operations(idxd_ops) do
    idxd_ops
    |> Enum.filter(&(&1 != :noop))
    |> Enum.sort_by(&(elem(&1, 1)))
    |> Enum.map(&(elem(&1, 0)))
  end

  defp index_op({%{insert: idx}, _} = op_with_orig_idx, idxd_ops) do
    insert_at_idx(idxd_ops, idx, op_with_orig_idx)
  end

  defp index_op({op, _} = op_with_orig_idx, idxd_ops) do
    replace_at_idx(idxd_ops, Operation.index(op), op_with_orig_idx)
  end

  defp insert_at_idx(list, idx, val) do
    list
    |> ensure_length(idx)
    |> List.insert_at(idx, val)
  end

  defp replace_at_idx(list, idx, val) do
    list
    |> ensure_length(idx + 1)
    |> List.replace_at(idx, val)
  end

  defp ensure_length(list, idx) when length(list) >= idx, do: list
  defp ensure_length(list, idx) do
    ensure_length(list ++ [:noop], idx)
  end
end
