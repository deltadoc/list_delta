defmodule ListDelta.IndexTest do
  use ExUnit.Case
  alias ListDelta.{Index, Operation}

  describe "indexing" do
    test "of single operation at zero point" do
      assert Index.new([op = Operation.insert(0, 3)]) == [op]
      assert Index.new([op = Operation.remove(0)]) == [op]
      assert Index.new([op = Operation.replace(0, 3)]) == [op]
      assert Index.new([op = Operation.change(0, 3)]) == [op]
    end

    test "of two inserts at different insert points" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(1, 5)
      ]
      assert Index.new(ops) == [op1, op2]
    end

    test "of two inserts at the same insert point" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(0, 5)
      ]
      assert Index.new(ops) == [op2, op1]
    end

    test "of three inserts at the same insert point" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(0, 5),
        op3 = Operation.insert(0, 6)
      ]
      assert Index.new(ops) == [op3, op2, op1]
    end

    test "of two inserts at two insert points separated by noop" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(3, 6)
      ]
      assert Index.new(ops) == [op1, :noop, :noop, op2]
    end

    test "of two inserts separated by noop, provided in reverse order" do
      ops = [
        op1 = Operation.insert(3, 3),
        op2 = Operation.insert(0, 6)
      ]
      assert Index.new(ops) == [op2, :noop, :noop, :noop, op1]
    end

    test "of single operation at non-zero point" do
      assert Index.new([op = Operation.remove(1)]) == [:noop, op]
      assert Index.new([op = Operation.replace(1, 3)]) == [:noop, op]
      assert Index.new([op = Operation.change(1, 5)]) == [:noop, op]
    end

    test "of insert and remove of different indexes in reverse order" do
      ops = [
        op1 = Operation.insert(3, 3),
        op2 = Operation.remove(0)
      ]
      assert Index.new(ops) == [op2, :noop, :noop, op1]
    end
  end
end
