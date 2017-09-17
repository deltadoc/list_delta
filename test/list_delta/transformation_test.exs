defmodule ListDelta.TransformationTest do
  use ExUnit.Case

  alias ListDelta.{Operation, Transformation}

  import Operation

  doctest Transformation

  describe "insert against another insert" do
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
      assert xf(b, a, :left) == ListDelta.new([remove(2), insert(1, "B"), insert(0, "A")])
      assert xf(b, a, :right) == ListDelta.insert(0, "A")
    end
  end

  describe "insert against remove" do
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

  describe "insert against replace" do
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

  describe "insert against change" do
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

  describe "remove against remove" do
    test "at the same index" do
      a = ListDelta.remove(0)
      b = ListDelta.remove(0)
      assert xf(a, b, :left) == ListDelta.new()
      assert xf(b, a, :right) == ListDelta.new()
    end

    test "at a different index" do
      a = ListDelta.remove(1)
      b = ListDelta.remove(3)
      assert xf(a, b, :left) == ListDelta.remove(2)
      assert xf(b, a, :right) == ListDelta.remove(1)
    end
  end

  describe "remove against replace" do
    test "at the same index" do
      a = ListDelta.remove(0)
      b = ListDelta.replace(0, "B")
      assert xf(a, b, :left) == ListDelta.insert(0, "B")
      assert xf(b, a, :right) == ListDelta.new()
    end

    test "at a higher index" do
      a = ListDelta.remove(2)
      b = ListDelta.replace(3, "B")
      assert xf(a, b, :left) == ListDelta.replace(2, "B")
      assert xf(b, a, :right) == ListDelta.remove(2)
    end

    test "at a lower index" do
      a = ListDelta.remove(2)
      b = ListDelta.replace(1, "B")
      assert xf(a, b, :left) == ListDelta.replace(1, "B")
      assert xf(b, a, :right) == ListDelta.remove(2)
    end
  end

  describe "remove against change" do
    test "at the same index" do
      a = ListDelta.change(1, "C")
      b = ListDelta.remove(1)
      assert xf(a, b, :left) == ListDelta.remove(1)
      assert xf(b, a, :right) == ListDelta.new()
    end

    test "at a higher index" do
      a = ListDelta.change(2, "C")
      b = ListDelta.remove(1)
      assert xf(a, b, :left) == ListDelta.remove(1)
      assert xf(b, a, :right) == ListDelta.change(1, "C")
    end

    test "at a lower index" do
      a = ListDelta.change(2, "C")
      b = ListDelta.remove(3)
      assert xf(a, b, :left) == ListDelta.remove(3)
      assert xf(b, a, :right) == ListDelta.change(2, "C")
    end
  end

  describe "replace against replace" do
    test "at the same index" do
      a = ListDelta.replace(1, "C")
      b = ListDelta.replace(1, "E")
      assert xf(a, b, :left) == ListDelta.new()
      assert xf(a, b, :right) == ListDelta.replace(1, "E")
      assert xf(b, a, :left) == ListDelta.new()
      assert xf(b, a, :right) == ListDelta.replace(1, "C")
    end

    test "at a different index" do
      a = ListDelta.replace(1, "C")
      b = ListDelta.replace(2, "E")
      assert xf(a, b, :left) == ListDelta.replace(2, "E")
      assert xf(b, a, :right) == ListDelta.replace(1, "C")
      assert xf(b, a, :left) == ListDelta.replace(1, "C")
      assert xf(a, b, :right) == ListDelta.replace(2, "E")
    end
  end

  describe "replace against change" do
    test "at the same index" do
      a = ListDelta.change(1, "B")
      b = ListDelta.replace(1, "E")
      assert xf(a, b, :left) == ListDelta.replace(1, "E")
      assert xf(b, a, :right) == ListDelta.new()
    end

    test "at a different index" do
      a = ListDelta.change(1, "B")
      b = ListDelta.replace(2, "E")
      assert xf(a, b, :left) == ListDelta.replace(2, "E")
      assert xf(b, a, :right) == ListDelta.change(1, "B")
    end
  end

  describe "change against change" do
  end

  defp xf(left, right, priority), do: ListDelta.transform(left, right, priority)
end
