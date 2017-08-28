defmodule ListDelta.OpsIndexerTest do
  use ExUnit.Case

  alias ListDelta.{OpsIndexer, Operation}

  test "indexes single operation" do
    assert OpsIndexer.index_ops([op = Operation.insert(0, 3)]) == [{op, 0}]
    assert OpsIndexer.index_ops([op = Operation.remove(0)]) == [{op, 0}]
    assert OpsIndexer.index_ops([op = Operation.replace(0, 3)]) == [{op, 0}]
    assert OpsIndexer.index_ops([op = Operation.change(0, 3)]) == [{op, 0}]
  end

  test "indexes two inserts at different insert points" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(1, 5)
    ]
    assert OpsIndexer.index_ops(ops) == [{op1, 0}, {op2, 1}]
  end

  test "indexes two inserts at the same insert point" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(0, 5)
    ]
    assert OpsIndexer.index_ops(ops) == [{op2, 1}, {op1, 0}]
  end

  test "indexes three inserts at the same insert point" do
    ops = [
      op1 = Operation.insert(0, 3),
      op2 = Operation.insert(0, 5),
      op3 = Operation.insert(0, 6)
    ]
    assert OpsIndexer.index_ops(ops) == [{op3, 2}, {op2, 1}, {op1, 0}]
  end
end
