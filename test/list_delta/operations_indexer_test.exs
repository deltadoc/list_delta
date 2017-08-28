defmodule ListDelta.OperationsIndexerTest do
  use ExUnit.Case
  alias ListDelta.Operation
  import ListDelta.OperationsIndexer

  test "indexes single operation" do
    assert index_operations([op = Operation.insert(0, 3)]) == [{op, 0}]
    assert index_operations([op = Operation.remove(0)]) == [{op, 0}]
    assert index_operations([op = Operation.replace(0, 3)]) == [{op, 0}]
    assert index_operations([op = Operation.change(0, 3)]) == [{op, 0}]
  end

  test "indexes two inserts at different insert points" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(1, 5)
    ]
    assert index_operations(ops) == [{op1, 0}, {op2, 1}]
  end

  test "indexes two inserts at the same insert point" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(0, 5)
    ]
    assert index_operations(ops) == [{op2, 1}, {op1, 0}]
  end

  test "indexes three inserts at the same insert point" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(0, 5),
      op3 = Operation.insert(0, 6)
    ]
    assert index_operations(ops) == [{op3, 2}, {op2, 1}, {op1, 0}]
  end

  test "indexes two inserts at two insert points separated by noop" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(3, 6)
    ]
    assert index_operations(ops) == [{op1, 0}, :noop, :noop, {op2, 1}]
  end

  test "indexes two inserts separated by noop, provided in reverse order" do
    ops = [
      op1 = Operation.insert(3, 3),
      op2 = Operation.insert(0, 6)
    ]
    assert index_operations(ops) == [{op2, 1}, :noop, :noop, :noop, {op1, 0}]
  end
end