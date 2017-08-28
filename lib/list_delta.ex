defmodule ListDelta do
  defstruct ops: []

  alias ListDelta.{Operation, Composition}

  def new, do: %ListDelta{}

  def insert(delta \\ %ListDelta{}, idx, init) do
    append(delta, Operation.insert(idx, init))
  end

  def remove(delta \\ %ListDelta{}, idx) do
    append(delta, Operation.remove(idx))
  end

  def replace(delta \\ %ListDelta{}, idx, new_init) do
    append(delta, Operation.replace(idx, new_init))
  end

  def change(delta \\ %ListDelta{}, idx, item_delta) do
    append(delta, Operation.change(idx, item_delta))
  end

  def operations(delta), do: delta.ops

  def compose(first, second) do
    first.ops
    |> Composition.compose(second.ops)
    |> wrap()
  end

  defp append(%ListDelta{ops: ops}, op), do: wrap(ops ++ [op])
  defp wrap(ops), do: %ListDelta{ops: ops}
end
