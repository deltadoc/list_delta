defmodule ListDelta.Operation do
  def insert(idx, init), do: %{insert: idx, init: init}
  def remove(idx), do: %{remove: idx}
  def replace(idx, new_init), do: %{replace: idx, init: new_init}
  def change(idx, delta), do: %{change: idx, delta: delta}

  def type(%{insert: _}), do: :insert
  def type(%{remove: _}), do: :remove
  def type(%{replace: _}), do: :replace
  def type(%{change: _}), do: :change

  def index(%{insert: idx}), do: idx
  def index(%{remove: idx}), do: idx
  def index(%{replace: idx}), do: idx
  def index(%{change: idx}), do: idx

  def change_index(%{insert: _, init: init}, idx), do: insert(idx, init)
  def change_index(%{remove: _}, idx), do: remove(idx)
  def change_index(%{replace: _, init: init}, idx), do: replace(idx, init)
  def change_index(%{change: _, delta: delta}, idx), do: change(idx, delta)
end
