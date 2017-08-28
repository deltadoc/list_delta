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

  describe "composing" do
    test "insert with insert at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.insert(1, false)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(1, false)
      ]
    end

    test "insert with insert at the same index" do
      a = ListDelta.insert(0, 2)
      b = ListDelta.insert(0, nil)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 2),
        Operation.insert(0, nil)
      ]
    end

    test "insert before another" do
      a = ListDelta.insert(1, 3)
      b = ListDelta.insert(0, 5)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(1, 3),
        Operation.insert(0, 5)
      ]
    end

    test "insert with remove at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.remove(4)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.remove(4)
      ]
    end

    test "insert immediately followed by remove" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(a, b)) == []
    end

    test "double insert with remove" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(0, 3)]
    end

    test "triple insert with remove" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
        |> ListDelta.insert(0, false)
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, nil)
      ]
    end

    test "triple insert with remove at different index" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
        |> ListDelta.insert(0, false)
      b = ListDelta.remove(1)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, false)
      ]
    end
  end

  defp ops(delta), do: ListDelta.operations(delta)
end
