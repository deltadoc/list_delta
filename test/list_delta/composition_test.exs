defmodule ListDelta.CompositionTest do
  use ExUnit.Case
  use EQC.ExUnit

  alias ListDelta.{Operation, Composition}
  import ListDelta.Generators

  doctest Composition

  property "(a + b) + c = a + (b + c)" do
    forall {delta_a, delta_b} <- {delta(), delta()} do
      list = ListDelta.new()
      list_a = ListDelta.compose(list, delta_a)
      list_b = ListDelta.compose(list_a, delta_b)

      delta_c = ListDelta.compose(delta_a, delta_b)
      list_c = ListDelta.compose(list, delta_c)

      ensure list_b == list_c
    end
  end

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

    test "with insert at lower index" do
      a = ListDelta.insert(2, 3)
      b = ListDelta.insert(0, 5)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(2, 3),
        Operation.insert(0, 5)
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
        Operation.insert(0, nil),
        Operation.insert(0, false),
        Operation.remove(1)
      ]
    end

    test "immediately followed by replace" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.replace(0, "text")
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(0, "text")]
    end

    test "two times with replace" do
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

    test "two times with replace of the second element" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.replace(1, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, nil),
        Operation.replace(1, "text")
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

    test "two times with change of second element" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.change(1, "text")
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, nil),
        Operation.change(1, "text")
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

    test "immediately followed by move" do
      a = ListDelta.insert(0, "A")
      b = ListDelta.move(0, 6)
      assert ops(ListDelta.compose(a, b)) == [Operation.insert(6, "A")]
    end

    test "two times with move" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.move(0, 3)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(3, nil)
      ]
    end

    test "two times with move of second element" do
      a =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      b = ListDelta.move(1, 5)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.insert(0, nil),
        Operation.move(1, 5)
      ]
    end

    test "with move at different index" do
      a = ListDelta.insert(0, 3)
      b = ListDelta.move(2, 0)
      assert ops(ListDelta.compose(a, b)) == [
        Operation.insert(0, 3),
        Operation.move(2, 0)
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

    test "with insert at different index" do
      b = ListDelta.insert(1, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.insert(1, "text")
      ]
    end

    test "with change" do
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.change(0, "text")
      ]
    end

    test "with remove at the same index" do
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0)
      ]
    end

    test "with remove at different index" do
      b = ListDelta.remove(1)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.remove(1)
      ]
    end

    test "with replace" do
      b = ListDelta.replace(0, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.replace(0, 5)
      ]
    end

    test "with move" do
      b = ListDelta.move(0, 3)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0),
        Operation.move(0, 3)
      ]
    end
  end

  describe "composing replace" do
    @op ListDelta.replace(0, 123)

    test "with insert" do
      b = ListDelta.insert(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.insert(0, "text")
      ]
    end

    test "with change at the same index" do
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, "text")
      ]
    end

    test "with change at different index" do
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

    test "with remove at different index" do
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

    test "with replace at different index" do
      b = ListDelta.replace(1, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.replace(1, 5)
      ]
    end

    test "with move" do
      b = ListDelta.move(0, 3)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.replace(0, 123),
        Operation.move(0, 3)
      ]
    end
  end

  describe "composing move" do
    @op ListDelta.move(0, 3)

    test "with insert" do
      b = ListDelta.insert(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.insert(0, "text")
      ]
    end

    test "with remove at the same origin index" do
      b = ListDelta.remove(0)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.remove(0)
      ]
    end

    test "with remove at the same destination index" do
      b = ListDelta.remove(3)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.remove(0)
      ]
    end

    test "with remove at different origin and destination indexes" do
      b = ListDelta.remove(2)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.remove(2)
      ]
    end

    test "with replace" do
      b = ListDelta.replace(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.replace(0, "text")
      ]
    end

    test "with move at the same origin index" do
      b = ListDelta.move(0, 2)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.move(0, 2)
      ]
    end

    test "with move at the same destination index" do
      b = ListDelta.move(3, 2)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 2)
      ]
    end

    test "with move at different origin and destination indexes" do
      b = ListDelta.move(2, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.move(2, 5)
      ]
    end

    test "with change" do
      b = ListDelta.change(0, "B")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.move(0, 3),
        Operation.change(0, "B")
      ]
    end
  end

  describe "composing change" do
    @op ListDelta.change(0, "abc")

    test "with insert" do
      b = ListDelta.insert(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "abc"),
        Operation.insert(0, "text")
      ]
    end

    test "with change at the same index" do
      b = ListDelta.change(0, "text")
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "text")
      ]
    end

    test "with change at different index" do
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

    test "with remove at different index" do
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

    test "with replace at different index" do
      b = ListDelta.replace(1, 5)
      assert ops(ListDelta.compose(@op, b)) == [
        Operation.change(0, "abc"),
        Operation.replace(1, 5)
      ]
    end
  end

  defp ops(delta), do: ListDelta.operations(delta)
end
