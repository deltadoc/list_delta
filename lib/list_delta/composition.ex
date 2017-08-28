defmodule ListDelta.Composition do
  alias ListDelta.{OperationsIndexer, Operation, ItemDelta}

  def compose(first, second) do
    {OperationsIndexer.index_operations(first),
     OperationsIndexer.index_operations(second, length(first))}
    |> compose_idxd_ops()
    |> OperationsIndexer.unindex_operations()
    |> List.flatten()
  end

  defp compose_idxd_ops({first, second}) do
    for idx <- 0..Enum.max([length(first), length(second)]) do
      do_compose(Enum.at(first, idx, :noop), Enum.at(second, idx, :noop))
    end
  end

  defp do_compose(op_a, :noop), do: op_a
  defp do_compose(:noop, op_b), do: op_b

  defp do_compose({%{insert: _} = op_a, orig_idx},
                  {%{insert: _} = op_b, _}) do
    {[op_a, op_b], orig_idx}
  end

  defp do_compose({%{insert: idx}, orig_idx},
                  {%{replace: _, init: init}, _}) do
    {Operation.insert(idx, init), orig_idx}
  end

  defp do_compose({%{insert: idx, init: init}, orig_idx},
                  {%{change: _, delta: delta}, _}) do
    {Operation.insert(idx, ItemDelta.compose(init, delta)), orig_idx}
  end

  defp do_compose({%{remove: idx}, orig_idx},
                  {%{insert: _, init: init}, _}) do
    {Operation.replace(idx, init), orig_idx}
  end

  defp do_compose({%{remove: _}, _} = orig_rem,
                  {%{change: _}, _}) do
    orig_rem
  end

  defp do_compose({%{remove: _}, orig_idx}, {op_b, _}) do
    {op_b, orig_idx}
  end

  defp do_compose({%{replace: idx, init: init}, orig_idx},
                  {%{change: _, delta: delta}, _}) do
    {Operation.replace(idx, ItemDelta.compose(init, delta)), orig_idx}
  end

  defp do_compose({%{replace: _}, orig_idx},
                  {%{remove: _} = rem, _}) do
    {rem, orig_idx}
  end

  defp do_compose({%{change: idx, delta: delta_a}, orig_idx},
                  {%{change: _, delta: delta_b}, _}) do
    {Operation.change(idx, ItemDelta.compose(delta_a, delta_b)), orig_idx}
  end

  defp do_compose({%{change: _}, orig_idx},
                  {%{remove: _} = rem, _}) do
    {rem, orig_idx}
  end

  defp do_compose({_, orig_idx}, {%{insert: idx, init: init}, _}) do
    {Operation.replace(idx, init), orig_idx}
  end

  defp do_compose({_, orig_idx}, {%{replace: _} = rep, _}) do
    {rep, orig_idx}
  end

  defp do_compose(_, {%{remove: _}, _}) do
    :noop
  end
end
