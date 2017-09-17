defmodule ListDelta.Generators do
  use EQC.ExUnit

  alias ListDelta.Operation

  @max_index 100

  def delta do
    let ops <- list(operation()) do
      ListDelta.new(ops)
    end
  end

  def operation do
    oneof [insert(), remove(), replace(), change()]
  end

  def insert do
    let [idx <- item_index(), init <- item_delta()] do
      Operation.insert(idx, init)
    end
  end

  def remove do
    let idx <- item_index() do
      Operation.remove(idx)
    end
  end

  def replace do
    let [idx <- item_index(), init <- item_delta()] do
      Operation.replace(idx, init)
    end
  end

  def change do
    let [idx <- item_index(), delta <- item_delta()] do
      Operation.change(idx, delta)
    end
  end

  def item_index do
    choose(1, @max_index)
  end

  def item_delta do
    oneof [int(), bool(), list(int()), utf8(), nil]
  end
end
