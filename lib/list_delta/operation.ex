defmodule ListDelta.Operation do
  def insert(idx, init), do: %{insert: idx, init: init}
  def remove(idx), do: %{remove: idx}
  def replace(idx, new_init), do: %{replace: idx, init: new_init}
  def change(idx, delta), do: %{change: idx, delta: delta}

  def type(%{insert: _}), do: :insert
  def type(%{remove: _}), do: :remove
  def type(%{replace: _}), do: :replace
  def type(%{change: _}), do: :change
end
