defmodule ListDeltaTest do
  use ExUnit.Case
  doctest ListDelta
  alias ListDelta.Operation

  describe "constructing" do
    test "insert" do
      assert ops(ListDelta.insert(1, nil)) == [Operation.insert(1, nil)]
    end

    test "remove" do
      assert ops(ListDelta.remove(1)) == [Operation.remove(1)]
    end

    test "replace" do
      assert ops(ListDelta.replace(1, 5)) == [Operation.replace(1, 5)]
    end

    test "change" do
      assert ops(ListDelta.change(1, 3)) == [Operation.change(1, 3)]
    end

    test "multiple operations" do
      delta =
        ListDelta.new()
        |> ListDelta.insert(1, nil)
        |> ListDelta.remove(2)
        |> ListDelta.replace(3, 4)
        |> ListDelta.change(4, false)
      operations = [
        Operation.insert(1, nil),
        Operation.remove(2),
        Operation.replace(3, 4),
        Operation.change(4, false)
      ]
      assert ops(delta) == operations
    end
  end

  defp ops(delta), do: ListDelta.operations(delta)
end
