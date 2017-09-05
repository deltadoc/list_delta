defmodule ListDelta.CompositionTest do
  use ExUnit.Case
  doctest ListDelta.Composition
  alias ListDelta.Operation

  describe "composing insert" do
    test "with insert at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.insert(2, false)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(2, false)
      ]
    end

    test "with insert at the same index" do
      a = ListDelta.insert(0, 2)
      b = ListDelta.insert(0, nil)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 2),
        Operation.insert(0, nil)
      ]
    end

    test "before another" do
      a = ListDelta.insert(2, 3)
      b = ListDelta.insert(0, 5)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 5),
        Operation.insert(3, 3)
      ]
    end

    test "with remove at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.remove(4)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.remove(4)
      ]
    end

    test "immediately followed by remove" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(a, b)) == []
    end

    test "two times followed by remove" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(0, 3)]
    end

    test "three times followed by remove" do
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

    test "three times followed by remove of follow-up index" do
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

    test "immediately followed by replace" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.replace(0, "text")
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(0, "text")]
    end

    test "two times with with replace" do
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

    test "with replace at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.replace(2, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.replace(2, "text")
      ]
    end

    test "immediately followed by change" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.change(0, 6)
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(0, 6)]
    end

    test "two times with change" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, "text")
      ]
    end

    test "with change at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.change(2, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.change(2, "text")
      ]
    end
  end

  describe "composing remove" do
    @op ListDelta.remove(0)

    test "with insert at the same index" do
      b = ListDelta.insert(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, "text")
      ]
    end

    test "with insert at different indexes" do
      b = ListDelta.insert(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.insert(1, "text")
      ]
    end

    test "with change at the same index" do
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0)
      ]
    end

    test "with change at different indexes" do
      b = ListDelta.change(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.change(1, "text")
      ]
    end

    test "with remove at the same index" do
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0)
      ]
    end

    test "with remove at different indexes" do
      b = ListDelta.remove(1)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.remove(1)
      ]
    end

    test "with replace at the same index" do
      b = ListDelta.replace(0, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 5)
      ]
    end

    test "with replace at different indexes" do
      b = ListDelta.replace(1, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.replace(1, 5)
      ]
    end
  end

  describe "composing replace" do
    @op ListDelta.replace(0, 123)

    test "with insert at the same index" do
      b = ListDelta.insert(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.insert(0, "text"),
        Operation.replace(1, 123)
      ]
    end

    test "with insert at different indexes" do
      b = ListDelta.insert(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.insert(1, "text")
      ]
    end

    test "with change at the same index" do
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, "text")
      ]
    end

    test "with change at different indexes" do
      b = ListDelta.change(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.change(1, "text")
      ]
    end

    test "with remove at the same index" do
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0)
      ]
    end

    test "with remove at different indexes" do
      b = ListDelta.remove(1)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.remove(1)
      ]
    end

    test "with replace at the same index" do
      b = ListDelta.replace(0, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 5)
      ]
    end

    test "with replace at different indexes" do
      b = ListDelta.replace(1, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.replace(1, 5)
      ]
    end
  end

  describe "composing change" do
    @op ListDelta.change(0, "abc")

    test "with insert at the same index" do
      b = ListDelta.insert(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.insert(0, "text"),
        Operation.change(1, "abc")
      ]
    end

    test "with insert at different indexes" do
      b = ListDelta.insert(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "abc"),
        Operation.insert(1, "text")
      ]
    end

    test "with change at the same index" do
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "text")
      ]
    end

    test "with change at different indexes" do
      b = ListDelta.change(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "abc"),
        Operation.change(1, "text")
      ]
    end

    test "with remove at the same index" do
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0)
      ]
    end

    test "with remove at different indexes" do
      b = ListDelta.remove(1)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "abc"),
        Operation.remove(1)
      ]
    end

    test "with replace at the same index" do
      b = ListDelta.replace(0, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 5)
      ]
    end

    test "with replace at different indexes" do
      b = ListDelta.replace(1, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "abc"),
        Operation.replace(1, 5)
      ]
    end
  end

  describe "normalisation" do
    test "of index streaks" do
      delta_a =
        ListDelta.new()
        |> ListDelta.insert(0, "A")
        |> ListDelta.insert(0, "B")
        |> ListDelta.insert(0, "C")
        |> ListDelta.insert(0, "D")
      delta_b =
        ListDelta.new()
        |> ListDelta.insert(0, "D")
        |> ListDelta.insert(1, "C")
        |> ListDelta.insert(2, "B")
        |> ListDelta.insert(3, "A")
      assert delta_a == delta_b
    end

    test "of index streaks with gaps" do
      delta_a =
        ListDelta.new()
        |> ListDelta.insert(0, "A")
        |> ListDelta.insert(0, "B")
        |> ListDelta.insert(3, "F")
        |> ListDelta.insert(3, "E")
      delta_b =
        ListDelta.new()
        |> ListDelta.insert(0, "B")
        |> ListDelta.insert(1, "A")
        |> ListDelta.insert(3, "E")
        |> ListDelta.insert(4, "F")
      assert delta_a == delta_b
    end
  end

  defp ops(delta), do: ListDelta.operations(delta)
end
