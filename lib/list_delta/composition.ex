defmodule ListDelta.Composition do
  def compose(first, second) do
    first.ops
    |> Enum.map(&(do_compose(&1, second.ops)))
    |> List.flatten()
    |> wrap_into_delta()
  end

  defp do_compose(%{insert: _} = op_a, [%{insert: _} = op_b]) do
    [op_a, op_b]
  end

  defp do_compose(%{insert: idx}, [%{remove: idx}]) do
    []
  end

  defp do_compose(%{insert: _} = op_a, [%{remove: _} = op_b]) do
    [op_a, op_b]
  end

  defp wrap_into_delta(ops), do: %ListDelta{ops: ops}
end
