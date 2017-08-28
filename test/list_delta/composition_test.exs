defmodule ListDelta.CompositionTest do
  use ExUnit.Case
  doctest ListDelta.Composition
  alias ListDelta.Operation

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

    test "insert immediately followed by replace" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.replace(0, "text")
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(0, "text")]
    end

    test "double insert with replace" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.replace(0, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, "text")
      ]
    end

    test "insert with replace at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.replace(1, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.replace(1, "text")
      ]
    end
  end

  defp ops(delta), do: ListDelta.operations(delta)
end
