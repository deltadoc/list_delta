defmodule ListDelta.Index do
  alias ListDelta.Operation

  def new, do: []
  def new(ops) do
    List.foldl(ops, new(), &add(&2, &1))
  end

  def add(ops_index, %{insert: idx} = op) do
    ops_index
    |> insert_at_index(idx, op)
    |> reindex_inserts()
  end
  def add(ops_index, op) do
    replace_at_index(ops_index, Operation.index(op), op)
  end

  def to_ordered_operations(ops_index) do
    ops_index
    |> Enum.chunk_by(&insert_with_index?/1)
    |> Enum.map(&Enum.reverse/1)
    |> List.flatten()
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

  defp reindex_inserts(ops_index) do
    ops_index
    |> Enum.with_index()
    |> Enum.map(&reindex_insert/1)
  end

  defp reindex_insert({op, actual_idx}) do
    case op do
      %{insert: _, init: init} -> Operation.insert(actual_idx, init)
      _ -> op
    end
  end

  defp ensure_length(list, idx) when length(list) >= idx, do: list
  defp ensure_length(list, idx), do: ensure_length(list ++ [:noop], idx)

  defp insert_with_index?(%{insert: idx}), do: {true, idx}
  defp insert_with_index?(_op), do: {false, 0}
end
