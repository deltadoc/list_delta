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
        Operation.insert(0, 3),
        Operation.insert(0, 5)
      ]
      assert Index.new(ops) == [
        Operation.insert(0, 5),
        Operation.insert(1, 3)
      ]
    end

    test "of three inserts at the same insert point" do
      ops = [
        Operation.insert(0, 3),
        Operation.insert(0, 5),
        Operation.insert(0, 6)
      ]
      assert Index.new(ops) == [
        Operation.insert(0, 6),
        Operation.insert(1, 5),
        Operation.insert(2, 3)
      ]
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
        Operation.insert(3, 3),
        Operation.insert(0, 6)
      ]
      assert Index.new(ops) == [
        Operation.insert(0, 6),
        :noop,
        :noop,
        :noop,
        Operation.insert(4, 3)
      ]
    end

    test "of single operation at non-zero point" do
      assert Index.new([op = Operation.insert(1, "B")]) == [:noop, op]
      assert Index.new([op = Operation.remove(1)]) == [:noop, op]
      assert Index.new([op = Operation.replace(1, 3)]) == [:noop, op]
      assert Index.new([op = Operation.change(1, 5)]) == [:noop, op]
    end

    test "of insert and remove of different indexes in reverse order" do
      ops = [
        Operation.insert(3, 3),
        Operation.remove(0)
      ]
      assert Index.new(ops) == [
        Operation.remove(0),
        :noop,
        :noop,
        Operation.insert(2, 3)
      ]
    end
  end

  describe "converting to ordered operations" do
    test "of single operation at zero point" do
      assert Index.to_operations([op = Operation.insert(0, 3)]) == [op]
      assert Index.to_operations([op = Operation.remove(0)]) == [op]
      assert Index.to_operations([op = Operation.replace(0, 3)]) == [op]
      assert Index.to_operations([op = Operation.change(0, 3)]) == [op]
    end

    test "of two inserts at different insert points" do
      ops_index = [
        Operation.insert(0, 3),
        :noop,
        Operation.insert(2, 5)
      ]
      assert Index.to_operations(ops_index) == [
        Operation.insert(0, 3),
        Operation.insert(2, 5)
      ]
    end

    test "of two inserts at the same insert point" do
      ops_index = [
        Operation.insert(0, 3),
        Operation.insert(1, 5)
      ]
      assert Index.to_operations(ops_index) == [
        Operation.insert(0, 5),
        Operation.insert(0, 3)
      ]
    end

    test "of three inserts at the same insert point" do
      ops_index = [
        Operation.insert(0, 6),
        Operation.insert(1, 5),
        Operation.insert(2, 3)
      ]
      assert Index.to_operations(ops_index) == [
        Operation.insert(0, 3),
        Operation.insert(0, 5),
        Operation.insert(0, 6)
      ]
    end

    test "of two inserts at two insert points separated by noop" do
      ops_index = [
        Operation.insert(0, 3),
        :noop,
        :noop,
        Operation.insert(3, 6)
      ]
      assert Index.to_operations(ops_index) == [
        Operation.insert(0, 3),
        Operation.insert(3, 6)
      ]
    end

    test "of insert and remove of different indexes in reverse order" do
      ops_index = [
        Operation.remove(0),
        :noop,
        :noop,
        Operation.insert(2, 3)
      ]
      assert Index.to_operations(ops_index) == [
        Operation.remove(0),
        Operation.insert(2, 3)
      ]
    end

    test "of insert not preceded by noop" do
      ops_index = [Operation.insert(1, "ABC")]
      assert Index.to_operations(ops_index) == [Operation.insert(0, "ABC")]
    end

    test "of insert preceded by noop" do
      ops_index = [:noop, Operation.insert(1, "ABC")]
      assert Index.to_operations(ops_index) == [Operation.insert(1, "ABC")]
    end
  end
end
