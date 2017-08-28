defmodule ListDelta.Composition do
  alias ListDelta.{OperationsIndexer, Operation}

  def compose(first, second) do
    fst_idxd = OperationsIndexer.index_operations(first)
    snd_idxd = OperationsIndexer.index_operations(second, length(first))
    for idx <- 0..Enum.max([length(fst_idxd), length(snd_idxd)]) do
      do_compose(Enum.at(fst_idxd, idx, :noop), Enum.at(snd_idxd, idx, :noop))
    end
    |> OperationsIndexer.unindex_operations()
    |> List.flatten()
  end

  defp do_compose(op_a, :noop), do: op_a
  defp do_compose(:noop, op_b), do: op_b

  defp do_compose({%{insert: _} = op_a, orig_idx}, {%{insert: _} = op_b, _}) do
    {[op_a, op_b], orig_idx}
  end

  defp do_compose({%{insert: idx}, orig_idx}, {%{replace: _, init: init}, _}) do
    {Operation.insert(idx, init), orig_idx}
  end

  defp do_compose(_, {%{remove: _}, _}) do
    :noop
  end
end
