defmodule ListDelta.Generators do
  use EQC.ExUnit

  alias ListDelta.Operation

  @max_length 1000

  def state do
    let items <- list(item_delta()) do
      Enum.reduce(items, ListDelta.new(), &ListDelta.insert(&2, 0, &1))
    end
  end

  def delta do
    let ops <- list(operation()) do
      ListDelta.new(ops)
    end
  end

  def state_delta(state) do
    let ops <- list(operation(list_length(state))) do
      ListDelta.new(ops)
    end
  end

  def priority_side do
    oneof [:left, :right]
  end

  def opposite(:left), do: :right
  def opposite(:right), do: :left

  defp operation(max_length \\ @max_length) do
    oneof [
      insert(max_length),
      remove(max_length),
      replace(max_length),
      change(max_length)
    ]
  end

  defp insert(max_length) do
    let [idx <- item_index(max_length), init <- item_delta()] do
      Operation.insert(idx, init)
    end
  end

  defp remove(max_length) do
    let idx <- item_index(max_length) do
      Operation.remove(idx)
    end
  end

  defp replace(max_length) do
    let [idx <- item_index(max_length), init <- item_delta()] do
      Operation.replace(idx, init)
    end
  end

  defp change(max_length) do
    let [idx <- item_index(max_length), delta <- item_delta()] do
      Operation.change(idx, delta)
    end
  end

  defp item_index(max_length) do
    choose(0, max_length)
  end

  defp item_delta do
    oneof [int(), bool(), list(int()), utf8(), nil]
  end

  defp list_length(delta) do
    delta
    |> ListDelta.operations()
    |> length()
  end
end
