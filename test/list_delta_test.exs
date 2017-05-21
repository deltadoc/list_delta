defmodule ListDeltaTest do
  use ExUnit.Case
  doctest ListDelta

  alias ListDelta.Operation

  describe "construct" do
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
  end

  defp ops(delta), do: ListDelta.operations(delta)
end
