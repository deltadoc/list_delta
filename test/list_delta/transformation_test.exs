defmodule ListDelta.TransformationTest do
  use ExUnit.Case

  alias ListDelta.{Operation, Transformation}

  import Operation

  doctest Transformation

  describe "transforming insert against another insert" do
    test "at the same index" do
      a = ListDelta.insert(0, "A")
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(1, "B")
      assert xf(a, b, :right) == ListDelta.insert(0, "B")
      assert xf(b, a, :left) == ListDelta.insert(1, "A")
      assert xf(b, a, :right) == ListDelta.insert(0, "A")
    end

    test "at a different index" do
      a = ListDelta.insert(0, "A")
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(3, "B")
      assert xf(a, b, :right) == ListDelta.insert(2, "B")
      assert xf(b, a, :left) == ListDelta.new([move(2, 1), insert(0, "A")])
      assert xf(b, a, :right) == ListDelta.insert(0, "A")
    end
  end

  describe "transforming insert against remove" do
    test "at the same index" do
      a = ListDelta.remove(0)
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.remove(1)
    end

    test "at a lower index" do
      a = ListDelta.remove(1)
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(1, "B")
      assert xf(b, a, :right) == ListDelta.remove(1)
    end

    test "at a higher index" do
      a = ListDelta.remove(2)
      b = ListDelta.insert(1, "B")
      assert xf(a, b, :left) == ListDelta.insert(1, "B")
      assert xf(b, a, :right) == ListDelta.remove(3)
    end
  end

  describe "transforming insert against replace" do
    test "at the same index" do
      a = ListDelta.replace(0, "A")
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.replace(1, "A")
    end

    test "at a lower index" do
      a = ListDelta.replace(1, "A")
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(2, "B")
      assert xf(b, a, :right) == ListDelta.replace(1, "A")
    end

    test "at a higher index" do
      a = ListDelta.replace(2, "A")
      b = ListDelta.insert(1, "B")
      assert xf(a, b, :left) == ListDelta.insert(1, "B")
      assert xf(b, a, :right) == ListDelta.replace(3, "A")
    end
  end

  describe "transforming insert against move" do
    test "from the same zero index" do
      a = ListDelta.move(0, 2)
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.move(1, 3)
    end

    test "to the same zero index" do
      a = ListDelta.move(2, 0)
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.move(3, 1)
    end

    test "from later element to an even later one" do
      a = ListDelta.move(1, 3)
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.move(2, 4)
    end

    test "from later element to an earlier, but still later one" do
      a = ListDelta.move(3, 2)
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.move(4, 3)
    end

    test "from earlier element to later, but still earlier one" do
      a = ListDelta.move(1, 2)
      b = ListDelta.insert(3, "B")
      assert xf(a, b, :left) == ListDelta.insert(3, "B")
      assert xf(b, a, :right) == ListDelta.move(1, 2)
    end

    test "from earlier element to an even earlier one" do
      a = ListDelta.move(2, 1)
      b = ListDelta.insert(3, "B")
      assert xf(a, b, :left) == ListDelta.insert(3, "B")
      assert xf(b, a, :right) == ListDelta.move(2, 1)
    end

    test "to the same high index" do
      a = ListDelta.move(1, 2)
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(2, "B")
      assert xf(b, a, :right) == ListDelta.new([move(1, 3), move(1, 2)])
    end

    test "from the same high index" do
      a = ListDelta.move(2, 1)
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(2, "B")
      assert xf(b, a, :right) == ListDelta.new([move(3, 1), move(2, 3)])
    end

    test "around it from lower to higher index" do
      a = ListDelta.move(1, 3)
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(2, "B")
      assert xf(b, a, :right) == ListDelta.new([move(1, 4), move(1, 2)])
    end

    test "around it from higher to lower index" do
      a = ListDelta.move(3, 1)
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(2, "B")
      assert xf(b, a, :right) == ListDelta.new([move(4, 1), move(2, 3)])
    end
  end

  describe "transforming insert against change" do
    test "at the same index" do
      a = ListDelta.change(0, "A")
      b = ListDelta.insert(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.change(1, "A")
    end

    test "at a lower index" do
      a = ListDelta.change(1, "A")
      b = ListDelta.insert(2, "B")
      assert xf(a, b, :left) == ListDelta.insert(2, "B")
      assert xf(b, a, :right) == ListDelta.change(1, "A")
    end

    test "at a higher index" do
      a = ListDelta.change(2, "A")
      b = ListDelta.insert(1, "B")
      assert xf(a, b, :left) == ListDelta.insert(1, "B")
      assert xf(b, a, :right) == ListDelta.change(3, "A")
    end
  end

  defp xf(left, right, priority), do: ListDelta.transform(left, right, priority)
end
