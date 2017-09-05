defmodule ListDelta do
  defstruct ops: []

  alias ListDelta.{Operation, Composition}

  def new, do: %ListDelta{}

  def insert(delta \\ %ListDelta{}, idx, init) do
    compose(delta, wrap(Operation.insert(idx, init)))
  end

  def remove(delta \\ %ListDelta{}, idx) do
    compose(delta, wrap(Operation.remove(idx)))
  end

  def replace(delta \\ %ListDelta{}, idx, new_init) do
    compose(delta, wrap(Operation.replace(idx, new_init)))
  end

  def change(delta \\ %ListDelta{}, idx, item_delta) do
    compose(delta, wrap(Operation.change(idx, item_delta)))
  end

  def operations(delta), do: delta.ops

  defdelegate compose(first, second), to: Composition

  defp wrap(ops), do: %ListDelta{ops: List.wrap(ops)}
end
