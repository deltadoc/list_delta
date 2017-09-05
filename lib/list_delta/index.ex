defmodule ListDelta.Index do
  alias ListDelta.Operation

  def index_operations(ops) do
    List.foldl(ops, [], &index_operation/2)
  end

  defp index_operation(%{insert: idx} = op, result) do
    insert_at_index(result, idx, op)
  end

  defp index_operation(op, result) do
    replace_at_index(result, Operation.index(op), op)
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

  defp ensure_length(list, idx) when length(list) >= idx, do: list
  defp ensure_length(list, idx), do: ensure_length(list ++ [:noop], idx)
end
