defmodule ListDelta.OperationsIndexer do
  alias ListDelta.Operation

  def index_operations(ops) do
    ops
    |> Enum.with_index()
    |> List.foldl([], &index_op/2)
  end

  defp index_op({%{insert: idx}, _} = op_with_orig_idx, idxd_ops) do
    insert_at_idx(idxd_ops, idx, op_with_orig_idx)
  end

  defp index_op({op, _} = op_with_orig_idx, idxd_ops) do
    idx = Operation.index(op)
    idxd_ops
    |> ensure_length(idx + 1)
    |> List.update_at(idx, fn _ -> op_with_orig_idx end)
  end

  defp insert_at_idx(list, idx, val) do
    list
    |> ensure_length(idx)
    |> List.insert_at(idx, val)
  end

  defp ensure_length(list, idx) when length(list) >= idx, do: list
  defp ensure_length(list, idx) do
    ensure_length(list ++ [:noop], idx)
  end
end
