defmodule ListDelta.Generators do
  use EQC.ExUnit

  alias ListDelta.Operation

  @max_idx 1000

  def delta do
    let ops <- list(operation()) do
      ListDelta.new(ops)
    end
  end

  def priority_side do
    oneof [:left, :right]
  end

  def scale_state_to(state, delta) do
    Enum.reduce ListDelta.operations(delta), state, fn
      %{remove: idx}, state ->
        state |> pad_state(idx) |> ListDelta.insert(idx, nil)
      op, state ->
        state |> pad_state(Operation.index(op))
    end
  end

  def opposite(:left), do: :right
  def opposite(:right), do: :left

  defp operation(max_idx \\ @max_idx) do
    oneof [
      insert(max_idx),
      remove(max_idx),
      replace(max_idx),
      change(max_idx)
    ]
  end

  defp insert(max_idx) do
    let [idx <- item_index(max_idx), init <- item_delta()] do
      Operation.insert(idx, init)
    end
  end

  defp remove(max_idx) do
    let idx <- item_index(max_idx) do
      Operation.remove(idx)
    end
  end

  defp replace(max_idx) do
    let [idx <- item_index(max_idx), init <- item_delta()] do
      Operation.replace(idx, init)
    end
  end

  defp change(max_idx) do
    let [idx <- item_index(max_idx), delta <- item_delta()] do
      Operation.change(idx, delta)
    end
  end

  defp item_index(max_idx) do
    choose(0, max_idx)
  end

  defp item_delta do
    oneof [int(), bool(), nil]
  end

  defp pad_state(state, target_length) do
    current_length = ListDelta.length(state)
    for idx <- Enum.to_list(current_length..target_length) do
      state = ListDelta.insert(state, idx, nil)
    end
    state
  end
end
