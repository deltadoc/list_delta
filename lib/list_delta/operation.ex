defmodule ListDelta.Operation do
  @moduledoc """
  Operations represent smallest possible change applicable to a list.

  This library differentiates 4 list operations:

  - `t:ListDelta.Operation.insert/0`: insert item into a list at specified
    index. Insert operation is the same as most linked list operations.
  - `t:ListDelta.Operation.remove/0`: remove item at specified index from a
    list.
  - `t:ListDelta.Operation.replace/0`: replace item under specified index with
    different init value (delta).
  - `t:ListDelta.Operation.change/0`: change value of an item under specified
    index.

  Every operation has an `index`, indicating the list index to use during
  insertion, removal, replacal or change.

  In addition to `index` every operation except `remove` comes with an `init` or
  `delta` payloads. Both `init` and `delta` values must have implementations of
  `ListDelta.ItemDelta` protocol. This allows item values themselves to be
  recursively composed and transformed much like the `ListDelta` itself.
  """

  @typedoc """
  Insert operation represents intention to insert element into a list.

  Most ListDelta operations act like the MapDelta counterparts. Insert, however,
  is a very different story. If you ever worked with linked lists, you know that
  you can easily insert more than one item at the same index:

    insert 0, a + insert 0, b + insert 0, c

  will result in a following list:

    [c, b, a]

  Perhaps more interesting is that you can create exactly the same list using
  completely different set of inserts:

    insert 0, c + insert 1, b + insert 2, a

  From the ListDelta point of view these two sets of operations are considered
  equal. You can learn more about that in `ListDelta.Index`.

  Item value is provided via `init` key and must be a value that has appropriate
  `ListDelta.ItemDelta` implementation. You can think of it as an initial delta
  of a value. This value would be composed with all consequent change deltas.
  """
  @type insert :: %{insert: item_index, init: item_delta}

  @typedoc """
  Remove operation represents an intention to remove an item from a list.
  """
  @type remove :: %{remove: item_index}

  @typedoc """
  Replace operation represents an intention to replace an item in a list.

  New value is provided via `init` key and must be a value that has appropriate
  `ListDelta.ItemDelta` implementation. You can think of it as an initial delta
  of a value. This value would be composed with all consequent change deltas.
  """
  @type replace :: %{replace: item_index, init: item_delta}

  @typedoc """
  Change operation represents an intention to change an item value in a list.

  Value change is provided via `delta` key and must be compatible with both the
  item `init` value provided earlier and all the precursor changes.
  """
  @type change :: %{change: item_index, delta: item_delta}

  @typedoc """
  An operation. Either `insert`, `remove`, `replace` or `change`.
  """
  @type t :: insert | remove | replace | change

  @typedoc """
  Atom representing operation type.
  """
  @type type :: :insert | :remove | :replace | :change

  @typedoc """
  A list item index represented as a non-negative integer.
  """
  @type item_index :: non_neg_integer

  @typedoc """
  A map item delta. Must implement `ListDelta.ItemDelta` protocol.
  """
  @type item_delta :: any

  @doc """
  Creates a new `insert` operation.

  ## Example

      iex> ListDelta.Operation.insert(0, "Hello")
      %{insert: 0, init: "Hello"}
  """
  @spec insert(item_index, item_delta) :: insert
  def insert(idx, init), do: %{insert: idx, init: init}

  @doc """
  Creates a new `remove` operation.

  ## Example

      iex> ListDelta.Operation.remove(5)
      %{remove: 5}
  """
  @spec remove(item_index) :: remove
  def remove(idx), do: %{remove: idx}

  @doc """
  Creates a new `replace` operation.

  ## Example

      iex> ListDelta.Operation.replace(4, false)
      %{replace: 4, init: false}
  """
  @spec replace(item_index, item_delta) :: replace
  def replace(idx, new_init), do: %{replace: idx, init: new_init}

  @doc """
  Creates a new `change` operation.

  ## Example

      iex> ListDelta.Operation.change(5, nil)
      %{change: 5, delta: nil}
  """
  @spec change(item_index, item_delta) :: change
  def change(idx, delta), do: %{change: idx, delta: delta}

  @doc """
  Returns type of an operation.

  ## Example

      iex> ListDelta.Operation.type(%{remove: 5})
      :remove
  """
  @spec type(t) :: type
  def type(op)
  def type(%{insert: _}), do: :insert
  def type(%{remove: _}), do: :remove
  def type(%{replace: _}), do: :replace
  def type(%{change: _}), do: :change

  @doc """
  Returns an operation index.

  ## Example

      iex> ListDelta.Operation.index(%{change: 5, delta: 3})
      5
  """
  @spec index(t) :: item_index
  def index(op)
  def index(%{insert: idx}), do: idx
  def index(%{remove: idx}), do: idx
  def index(%{replace: idx}), do: idx
  def index(%{change: idx}), do: idx

  @doc """
  Changes given operation index.

  ## Example

      iex> ListDelta.Operation.change_index(%{insert: 3, init: "Hi"}, 5)
      %{insert: 5, init: "Hi"}
  """
  @spec change_index(t, item_index) :: t
  def change_index(op, idx)
  def change_index(%{insert: _, init: init}, idx), do: insert(idx, init)
  def change_index(%{remove: _}, idx), do: remove(idx)
  def change_index(%{replace: _, init: init}, idx), do: replace(idx, init)
  def change_index(%{change: _, delta: delta}, idx), do: change(idx, delta)
end
