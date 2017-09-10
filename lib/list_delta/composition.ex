defmodule ListDelta.Composition do
  alias ListDelta.{Operation, ItemDelta}

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

  defp prepend(%{insert: idx, init: init},
              [%{remove: idx} | remainder]) do
    [Operation.replace(idx, init) | remainder]
  end

  defp prepend(%{remove: idx},
              [%{insert: idx} | remainder]) do
    remainder
  end

  defp prepend(%{remove: idx},
              [%{remove: idx} | _] = ops) do
    ops
  end

  defp prepend(%{remove: idx} = new_rem,
              [%{replace: idx} | remainder]) do
    [new_rem | remainder]
  end

  defp prepend(%{remove: new_idx},
              [%{move: orig_idx, to: new_idx} | remainder]) do
    [Operation.remove(orig_idx) | remainder]
  end

  defp prepend(%{remove: idx} = new_rem,
              [%{change: idx} | remainder]) do
    [new_rem | remainder]
  end

  defp prepend(%{replace: idx, init: new_init},
              [%{insert: idx} | remainder]) do
    [Operation.insert(idx, new_init) | remainder]
  end

  defp prepend(%{replace: idx} = new_rep,
              [%{replace: idx} | remainder]) do
    [new_rep | remainder]
  end

  defp prepend(%{replace: idx} = new_rep,
              [%{change: idx} | remainder]) do
    [new_rep | remainder]
  end

  defp prepend(%{move: idx, to: new_idx},
              [%{insert: idx, init: init} | remainder]) do
    [Operation.insert(new_idx, init) | remainder]
  end

  defp prepend(%{move: interim_idx, to: final_idx},
              [%{move: orig_idx, to: interim_idx} | remainder]) do
    [Operation.move(orig_idx, final_idx) | remainder]
  end

  defp prepend(%{change: idx, delta: delta},
              [%{insert: idx, init: init} | remainder]) do
    [Operation.insert(idx, ItemDelta.compose(init, delta)) | remainder]
  end

  defp prepend(%{change: idx, delta: delta},
              [%{replace: idx, init: init} | remainder]) do
    [Operation.replace(idx, ItemDelta.compose(init, delta)) | remainder]
  end

  defp prepend(%{change: idx, delta: new_delta},
              [%{change: idx, delta: orig_delta} | remainder]) do
    [Operation.change(idx, ItemDelta.compose(orig_delta, new_delta)) | remainder]
  end

  defp prepend(op, ops) do
    [op | ops]
  end

  defp wrap_into_delta(ops), do: %ListDelta{ops: ops}
end
