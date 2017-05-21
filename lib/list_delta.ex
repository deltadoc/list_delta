defmodule ListDelta do
  defstruct ops: []

  defmodule Operation do
    def insert(idx, init), do: %{insert: idx, init: init}
    def remove(idx), do: %{remove: idx}
    def replace(idx, new_init), do: %{replace: idx, init: new_init}
    def change(idx, delta), do: %{change: idx, delta: delta}
  end

  def insert(idx, init) do
    %ListDelta{ops: [Operation.insert(idx, init)]}
  end

  def remove(idx) do
    %ListDelta{ops: [Operation.remove(idx)]}
  end

  def replace(idx, new_init) do
    %ListDelta{ops: [Operation.replace(idx, new_init)]}
  end

  def change(idx, item_delta) do
    %ListDelta{ops: [Operation.change(idx, item_delta)]}
  end

  def operations(delta), do: delta.ops
end
