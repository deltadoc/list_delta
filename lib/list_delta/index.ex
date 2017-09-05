defmodule ListDelta.Index do
  @moduledoc """
  List index represents an intermediate delta step that is easy to compose and
  transform.

  ## Basic premise

  Index basically simplifies handling of complex history of operations, such as
  same-index or gapped inserts.

  Lets say we have the following set of inserts:

      insert 0, a
      insert 0, b
      insert 0, c

  and the following replace operation:

      replace 1, X

  If we are to compose those two sets of operations, what would the resulting
  set be and, more importantly, how would you go about composing it? Index makes
  it easy. With Index you can transform first set of operations into a following
  linked list using `ListDelta.Index.from_operations/1`:

      [
        0: insert 0, c
        1: insert 0, b
        2: insert 0, a
      ]

  With such representation, applying `replace 1, X` becomes trivial - we simply
  replace value of the operation at the "Index" `1` - `insert 0, b`.

  When we are done with composing or transforming, we can easily convert our
  index back into a set of operations with `ListDelta.Index.to_operations/1`:

      insert 0, a
      insert 0, X
      insert 0, c

  ## Operation sets with gaps

  Index also properly handles operation sets with gaps in them. In such cases
  gaps will be represented with `t:ListDelta.Index.noop/0`. For example, given
  the following list:

      insert 0, a
      insert 3, F

  you will get the following index:

      [
        0: insert 0, a
        1: noop
        2: noop
        3: insert 3, f
      ]

  ## Normalisation

  Perhaps the more interesting aspect of Index is that it also normalises
  resulting operation sets.

  The following list:

      [a, b, c]

  can be a result of this operation set:

      insert 0, c + insert 0, b + insert 0, a

  or it could have been constructed with this operation set instead:

      insert 0, a + insert 1, b + insert 2, c

  With Index it does not matter as it always normalises operations back to the
  zero-index notation (first set). This way you can compare the indexes of
  previous two operations and find that they are exactly the same.
  """

  alias ListDelta.Operation

  @typedoc """
  Index is a simple list consisting of operations and noops.
  """
  @type t :: [Operation.t | noop]

  @typedoc """
  Noop represents a gap in the list of operations.

  As the name suggests, this operation is a NO OPeration
  """
  @type noop :: :noop

  @doc """
  Creates new empty index.
  """
  def new, do: []

  @doc """
  Creates new Index using a given set of operations.

  ## Example

      iex> ListDelta.Index.from_operations([%{insert: 2, init: "Hi"}])
      [:noop, :noop, %{insert: 2, init: "Hi"}]
  """
  @spec from_operations([Operation.t]) :: t
  def from_operations(ops), do: List.foldl(ops, new(), &add(&2, &1))

  @doc """
  Converts index back into a set of operations.

  ## Example

      iex> ListDelta.Index.to_operations([:noop, :noop, %{insert: 2, init: "Hi"}])
      [%{insert: 2, init: "Hi"}]
  """
  @spec to_operations(t) :: [Operation.t]
  def to_operations(ops_index) do
    ops_index
    |> List.foldl([], &prepend_op(&2, &1))
    |> Enum.filter(&(&1 != :noop))
    |> Enum.reverse()
  end

  @doc """
  Adds a single operation to an index.
  """
  @spec add(t, Operation.t) :: t
  def add(ops_index, %{insert: idx} = op) do
    ops_index
    |> insert_at_index(idx, op)
    |> reindex_ops()
  end
  def add(ops_index, %{remove: idx} = op) do
    ops_index
    |> List.delete_at(idx)
    |> replace_at_index(idx, op)
    |> reindex_ops()
  end
  def add(ops_index, op) do
    replace_at_index(ops_index, Operation.index(op), op)
  end

  @doc """
  Replaces operation in the index.
  """
  @spec replace_at(t, non_neg_integer, Operation.t) :: t
  defdelegate replace_at(ops_index, idx, op), to: List

  @doc """
  Delete operation from an index.
  """
  @spec delete_at(t, non_neg_integer) :: t
  defdelegate delete_at(ops_index, idx), to: List

  defp insert_at_index(list, idx, val) do
    list
    |> ensure_length(idx)
    |> List.insert_at(idx, val)
  end

  defp replace_at_index(list, idx, val) do
    list
    |> ensure_length(idx + 1)
    |> List.replace_at(idx, val)
  end

  defp reindex_ops(ops_index) do
    Enum.map Enum.with_index(ops_index), fn
      {:noop, _} -> :noop
      {op, idx} -> Operation.change_index(op, idx)
    end
  end

  defp prepend_op([%{insert: prev_idx} = prev_ins | remainder],
                   %{insert: _, init: init}) do
    [prev_ins | prepend_op(remainder, Operation.insert(prev_idx, init))]
  end
  defp prepend_op([], %{insert: _, init: init}) do
    [Operation.insert(0, init)]
  end
  defp prepend_op(ops, op) do
    [op | ops]
  end

  defp ensure_length(list, idx) when length(list) >= idx, do: list
  defp ensure_length(list, idx), do: ensure_length(list ++ [:noop], idx)
end
