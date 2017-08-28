defmodule ListDelta.OperationsIndexerTest do
  use ExUnit.Case
  alias ListDelta.Operation
  import ListDelta.OperationsIndexer

  describe "indexing" do
    test "of single operation at zero point" do
      assert index_operations([op = Operation.insert(0, 3)]) == [{op, 0}]
      assert index_operations([op = Operation.remove(0)]) == [{op, 0}]
      assert index_operations([op = Operation.replace(0, 3)]) == [{op, 0}]
      assert index_operations([op = Operation.change(0, 3)]) == [{op, 0}]
    end

    test "of two inserts at different insert points" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(1, 5)
      ]
      assert index_operations(ops) == [{op1, 0}, {op2, 1}]
    end

    test "of two inserts at the same insert point" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(0, 5)
      ]
      assert index_operations(ops) == [{op2, 1}, {op1, 0}]
    end

    test "of three inserts at the same insert point" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(0, 5),
        op3 = Operation.insert(0, 6)
      ]
      assert index_operations(ops) == [{op3, 2}, {op2, 1}, {op1, 0}]
    end

    test "of two inserts at two insert points separated by noop" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(3, 6)
      ]
      assert index_operations(ops) == [{op1, 0}, :noop, :noop, {op2, 1}]
    end

    test "of two inserts separated by noop, provided in reverse order" do
      ops = [
        op1 = Operation.insert(3, 3),
        op2 = Operation.insert(0, 6)
      ]
      assert index_operations(ops) == [{op2, 1}, :noop, :noop, :noop, {op1, 0}]
    end

    test "of single operation at non-zero point" do
      assert index_operations([op = Operation.remove(1)]) == [:noop, {op, 0}]
      assert index_operations([op = Operation.replace(1, 3)]) == [:noop, {op, 0}]
      assert index_operations([op = Operation.change(1, 5)]) == [:noop, {op, 0}]
    end

    test "of insert and remove of different indexes in reverse order" do
      ops = [
        op1 = Operation.insert(3, 3),
        op2 = Operation.remove(0)
      ]
      assert index_operations(ops) == [{op2, 1}, :noop, :noop, {op1, 0}]
    end

    test "of two inserts with offset" do
      ops = [
        op1 = Operation.insert(0, 3),
        op2 = Operation.insert(1, 5)
      ]
      assert index_operations(ops, 6) == [{op1, 6}, {op2, 7}]
    end
  end

  describe "unindexing" do
    test "of single operation" do
      indexed_ops = [
        {op = Operation.insert(0, 1), 0}
      ]
      assert unindex_operations(indexed_ops) == [op]
    end

    test "of multiple operations" do
      indexed_ops = [
        {op1 = Operation.insert(0, 1), 0},
        {op2 = Operation.insert(1, 3), 1},
      ]
      assert unindex_operations(indexed_ops) == [op1, op2]
    end

    test "of multiple same operations in reverse order" do
      indexed_ops = [
        {op2 = Operation.insert(0, 6), 1},
        :noop,
        :noop,
        :noop,
        {op1 = Operation.insert(3, 3), 0}
      ]
      assert unindex_operations(indexed_ops) == [op1, op2]
    end

    test "of multiple different operations in reverse order" do
      indexed_ops = [
        {op2 = Operation.remove(0), 1},
        :noop,
        :noop,
        {op1 = Operation.insert(3, 3), 0}
      ]
      assert unindex_operations(indexed_ops) == [op1, op2]
    end
  end
end
