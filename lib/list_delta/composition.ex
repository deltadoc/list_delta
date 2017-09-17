defmodule ListDelta.Composition do
  alias ListDelta.{Operation, ItemDelta}

  import Operation

  def compose(first, second) do
    first_ops_reversed =
      first
      |> ListDelta.operations()
      |> Enum.reverse()
    second
    |> ListDelta.operations()
    |> List.foldl(first_ops_reversed, &prepend/2)
    |> Enum.reverse()
    |> wrap_into_delta()
  end

  #
  # Special rules for composing `insert` operations
  #

  defp prepend(%{insert: idx, init: init},
              [%{remove: idx} | remainder]) do
    [replace(idx, init) | remainder]
  end

  #
  # Special rules for composing `remove` operations
  #

  defp prepend(%{remove: idx},
              [%{insert: idx} | remainder]) do
    remainder
  end

  defp prepend(%{remove: rem_idx},
              [%{insert: ins_idx} = ins | remainder])
  when rem_idx > ins_idx do
    [ins | prepend(remove(rem_idx - 1), remainder)]
  end

  defp prepend(%{remove: _} = rem,
              [%{insert: _} = ins | remainder]) do
    [ins | prepend(rem, remainder)]
  end

  defp prepend(%{remove: idx},
              [%{remove: idx} | _] = operations) do
    operations
  end

  defp prepend(%{remove: idx} = remove,
              [%{replace: idx} | remainder]) do
    [remove | remainder]
  end

  defp prepend(%{remove: idx} = remove,
              [%{change: idx} | remainder]) do
    [remove | remainder]
  end

  #
  # Special rules for composing `replace` operations
  #

  defp prepend(%{replace: idx, init: new_init},
              [%{insert: idx} | remainder]) do
    [insert(idx, new_init) | remainder]
  end

  defp prepend(%{replace: idx} = replace,
              [%{replace: idx} | remainder]) do
    [replace | remainder]
  end

  defp prepend(%{replace: idx} = replace,
              [%{change: idx} | remainder]) do
    [replace | remainder]
  end

  #
  # Special rules for composing `change` operations
  #

  defp prepend(%{change: idx, delta: delta},
              [%{insert: idx, init: init} | remainder]) do
    [insert(idx, ItemDelta.compose(init, delta)) | remainder]
  end

  defp prepend(%{change: idx, delta: delta},
              [%{replace: idx, init: init} | remainder]) do
    [replace(idx, ItemDelta.compose(init, delta)) | remainder]
  end

  defp prepend(%{change: idx, delta: new_delta},
              [%{change: idx, delta: orig_delta} | remainder]) do
    [change(idx, ItemDelta.compose(orig_delta, new_delta)) | remainder]
  end

  #
  # Composing the rest
  #

  defp prepend(op, ops) do
    [op | ops]
  end

  defp wrap_into_delta(ops), do: %ListDelta{ops: ops}
end
