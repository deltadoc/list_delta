defmodule ListDelta.Composition do
  alias ListDelta.{Index, Operation, ItemDelta}

  def compose(first, second) do
    {Index.new(first), Index.new(second)}
    |> do_compose(Index.new())
    |> Index.to_operations()
  end

  # COMPOSING WITH EXHAUSTED indexes

  defp do_compose({[], []}, ops_index), do: ops_index
  defp do_compose({a, []}, ops_index), do: do_compose({a, [:noop]}, ops_index)
  defp do_compose({[], b}, ops_index), do: do_compose({[:noop], b}, ops_index)

  # COMPOSING :noop

  defp do_compose({[:noop | remainder_a],
                   [:noop | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(ops_index)
  end
  defp do_compose({[op_a | remainder_a],
                   [:noop | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, op_a))
  end
  defp do_compose({[:noop | remainder_a],
                   [op_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, op_b))
  end

  # COMPOSING insert

  defp do_compose({[%{insert: _} = ins_a | remainder_a],
                   [%{insert: _} = ins_b | remainder_b]}, ops_index) do
    new_index =
      ops_index
      |> Index.add(ins_a)
      |> Index.add(ins_b)
    {remainder_a, remainder_b}
    |> do_compose(new_index)
  end
  defp do_compose({[%{insert: _} | remainder_a],
                   [%{remove: _} | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(ops_index)
  end
  defp do_compose({[%{insert: idx} | remainder_a],
                   [%{replace: _, init: init} | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, Operation.insert(idx, init)))
  end
  defp do_compose({[%{insert: idx, init: init} | remainder_a],
                   [%{change: _, delta: delta} | remainder_b]}, ops_index) do
    new_init = ItemDelta.compose(init, delta)
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, Operation.insert(idx, new_init)))
  end

  # COMPOSING remove

  defp do_compose({[%{remove: idx} | remainder_a],
                   [%{insert: _, init: init} | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, Operation.replace(idx, init)))
  end
  defp do_compose({[%{remove: _} | remainder_a],
                   [%{remove: _} = rem_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rem_b))
  end
  defp do_compose({[%{remove: _} | remainder_a],
                   [%{replace: _} = rep_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rep_b))
  end
  defp do_compose({[%{remove: _} = rem_a | remainder_a],
                   [%{change: _} | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rem_a))
  end

  # COMPOSING replace

  defp do_compose({[%{replace: _} = rep_a | remainder_a],
                   [%{insert: _} = ins_b | remainder_b]}, ops_index) do
    new_index =
      ops_index
      |> Index.add(rep_a)
      |> Index.add(ins_b)
    {remainder_a, remainder_b}
    |> do_compose(new_index)
  end
  defp do_compose({[%{replace: _} | remainder_a],
                   [%{remove: _} = rem_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rem_b))
  end
  defp do_compose({[%{replace: _} | remainder_a],
                   [%{replace: _} = rep_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rep_b))
  end
  defp do_compose({[%{replace: idx, init: init} | remainder_a],
                   [%{change: _, delta: delta} | remainder_b]}, ops_index) do
    new_init = ItemDelta.compose(init, delta)
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, Operation.replace(idx, new_init)))
  end

  # COMPOSING change

  defp do_compose({[%{change: _} = chg_a | remainder_a],
                   [%{insert: _} = ins_b | remainder_b]}, ops_index) do
    new_index =
      ops_index
      |> Index.add(chg_a)
      |> Index.add(ins_b)
    {remainder_a, remainder_b}
    |> do_compose(new_index)
  end
  defp do_compose({[%{change: _} | remainder_a],
                   [%{remove: _} = rem_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rem_b))
  end
  defp do_compose({[%{change: _} | remainder_a],
                   [%{replace: _} = rep_b | remainder_b]}, ops_index) do
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, rep_b))
  end
  defp do_compose({[%{change: idx, delta: delta_a} | remainder_a],
                   [%{change: _, delta: delta_b} | remainder_b]}, ops_index) do
    new_delta = ItemDelta.compose(delta_a, delta_b)
    {remainder_a, remainder_b}
    |> do_compose(Index.add(ops_index, Operation.change(idx, new_delta)))
  end
end
