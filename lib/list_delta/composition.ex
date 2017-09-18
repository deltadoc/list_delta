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
    prepend(replace(idx, init), remainder)
  end

  defp prepend(%{insert: idx_a} = ins_a,
              [%{insert: idx_b, init: init_b} | remainder])
  when idx_b >= idx_a do
    prepend(insert(idx_b + 1, init_b), prepend(ins_a, remainder))
  end

  defp prepend(%{insert: ins_idx} = ins,
              [%{remove: rem_idx} | remainder])
  when rem_idx > ins_idx do
    prepend(remove(rem_idx + 1), prepend(ins, remainder))
  end

  defp prepend(%{insert: ins_idx} = ins,
              [%{replace: rep_idx, init: init} | remainder])
  when rep_idx > ins_idx do
    prepend(replace(rep_idx + 1, init), prepend(ins, remainder))
  end

  defp prepend(%{insert: ins_idx} = ins,
              [%{change: chg_idx, delta: delta} | remainder])
  when chg_idx > ins_idx do
    prepend(change(chg_idx + 1, delta), prepend(ins, remainder))
  end

  #
  # Special rules for composing `remove` operations
  #

  defp prepend(%{remove: idx},
              [%{insert: idx} | remainder]) do
    remainder
  end

  defp prepend(%{remove: idx} = remove,
              [%{replace: idx} | remainder]) do
    prepend(remove, remainder)
  end

  defp prepend(%{remove: idx} = remove,
              [%{change: idx} | remainder]) do
    prepend(remove, remainder)
  end

  defp prepend(%{remove: rem_idx},
              [%{insert: ins_idx} = ins | remainder])
  when rem_idx == ins_idx + 1 do
    prepend(ins, prepend(remove(rem_idx - 1), remainder))
  end

  defp prepend(%{remove: rem_idx} = rem,
              [%{insert: ins_idx, init: init} | remainder])
  when ins_idx > rem_idx do
    prepend(insert(ins_idx - 1, init), prepend(rem, remainder))
  end

  defp prepend(%{remove: idx_a} = rem_a,
              [%{remove: idx_b} | remainder])
  when idx_b > idx_a do
    prepend(remove(idx_b - 1), prepend(rem_a, remainder))
  end

  defp prepend(%{remove: rem_idx} = rem,
              [%{replace: rep_idx, init: init} | remainder])
  when rep_idx > rem_idx do
    prepend(replace(rep_idx - 1, init), prepend(rem, remainder))
  end

  defp prepend(%{remove: rem_idx} = rem,
              [%{change: chg_idx, delta: delta} | remainder])
  when chg_idx > rem_idx do
    prepend(change(chg_idx - 1, delta), prepend(rem, remainder))
  end

  #
  # Special rules for composing `replace` operations
  #

  defp prepend(%{replace: idx, init: new_init},
              [%{insert: idx} | remainder]) do
    prepend(insert(idx, new_init), remainder)
  end

  defp prepend(%{replace: idx} = replace,
              [%{replace: idx} | remainder]) do
    prepend(replace, remainder)
  end

  defp prepend(%{replace: idx} = replace,
              [%{change: idx} | remainder]) do
    prepend(replace, remainder)
  end

  defp prepend(%{replace: rep_idx} = rep,
              [%{insert: ins_idx} = ins | remainder])
  when ins_idx > rep_idx do
    prepend(ins, prepend(rep, remainder))
  end

  defp prepend(%{replace: rep_idx} = rep,
              [%{remove: rem_idx} = rem | remainder])
  when rem_idx > rep_idx do
    prepend(rem, prepend(rep, remainder))
  end

  defp prepend(%{replace: idx_a} = rep_a,
              [%{replace: idx_b} = rep_b | remainder])
  when idx_b > idx_a do
    prepend(rep_b, prepend(rep_a, remainder))
  end

  defp prepend(%{replace: rep_idx} = rep,
              [%{change: chg_idx} = chg | remainder])
  when chg_idx > rep_idx do
    prepend(chg, prepend(rep, remainder))
  end

  #
  # Special rules for composing `change` operations
  #

  defp prepend(%{change: idx, delta: delta},
              [%{insert: idx, init: init} | remainder]) do
    prepend(insert(idx, ItemDelta.compose(init, delta)), remainder)
  end

  defp prepend(%{change: idx, delta: delta},
              [%{replace: idx, init: init} | remainder]) do
    prepend(replace(idx, ItemDelta.compose(init, delta)), remainder)
  end

  defp prepend(%{change: idx, delta: new_delta},
              [%{change: idx, delta: orig_delta} | remainder]) do
    prepend(change(idx, ItemDelta.compose(orig_delta, new_delta)), remainder)
  end

  defp prepend(%{change: chg_idx} = chg,
              [%{insert: ins_idx} = ins | remainder])
  when ins_idx > chg_idx do
    prepend(ins, prepend(chg, remainder))
  end

  defp prepend(%{change: chg_idx} = chg,
              [%{remove: rem_idx} = rem | remainder])
  when rem_idx > chg_idx do
    prepend(rem, prepend(chg, remainder))
  end

  defp prepend(%{change: chg_idx} = chg,
              [%{replace: rep_idx} = rep | remainder])
  when rep_idx > chg_idx do
    prepend(rep, prepend(chg, remainder))
  end

  defp prepend(%{change: idx_a} = chg_a,
              [%{change: idx_b} = chg_b | remainder])
  when idx_b > idx_a do
    prepend(chg_b, prepend(chg_a, remainder))
  end

  #
  # Composing the rest
  #

  defp prepend(op, ops) do
    [op | ops]
  end

  defp wrap_into_delta(ops), do: %ListDelta{ops: ops}
end
