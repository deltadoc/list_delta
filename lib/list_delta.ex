defmodule ListDelta do
  defstruct ops: []

  alias ListDelta.{Operation, Composition, Transformation}

  def new, do: %ListDelta{}
  def new(ops), do: List.foldl(ops, new(), &append(&2, &1))

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

  defdelegate compose(first, second), to: Composition
  defdelegate transform(left, right, priority), to: Transformation

  defp append(delta, op), do: compose(delta, wrap(op))
  defp wrap(ops), do: %ListDelta{ops: List.wrap(ops)}
end
