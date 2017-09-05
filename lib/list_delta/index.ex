defmodule ListDelta.Index do
  alias ListDelta.Operation

  def new, do: []
  def new(ops) do
    List.foldl(ops, new(), &add(&2, &1))
  end

  def add(ops_index, %{insert: idx} = op) do
    insert_at_index(ops_index, idx, op)
  end
  def add(ops_index, op) do
    replace_at_index(ops_index, Operation.index(op), op)
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
