defmodule ListDelta.OperationsIndexer do
  alias ListDelta.Operation

  def index_operations(ops) do
    ops
    |> Enum.with_index()
    |> List.foldl([], &index_op/2)
  end

  defp index_op({op, _} = op_with_orig_idx, idxd_ops) do
    type = Operation.type(op)
    idx = Operation.index(op)
    index_op(type, idx, op_with_orig_idx, idxd_ops)
  end

  defp index_op(:insert, idx, op_with_orig_idx, idxd_ops) do
    insert_at_idx(idxd_ops, idx, op_with_orig_idx)
  end

  defp index_op(_op_type, _idx, op_with_orig_idx, idxd_ops) do
    idxd_ops ++ [op_with_orig_idx]
  end

  defp insert_at_idx(list, idx, val) do
    list
    |> List.insert_at(idx, val)
  end
end
