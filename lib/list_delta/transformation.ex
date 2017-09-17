defmodule ListDelta.Transformation do
  alias ListDelta.{Operation, ItemDelta}

  import Operation

  def transform(left, right, priority) do
    left_ops = ListDelta.operations(left)
    right
    |> ListDelta.operations()
    |> Enum.map(&do_transform(left_ops, &1, priority))
    |> List.flatten()
    |> ListDelta.new()
  end

  defp do_transform([], op, _priority), do: op
  defp do_transform(lft_ops, ops, priority) when is_list(ops) do
    Enum.map(ops, &do_transform(lft_ops, &1, priority))
  end
  defp do_transform([lft_op | lft_remainder], op, priority) do
    do_transform(lft_remainder, transform_op(lft_op, op, priority), priority)
  end

  #
  # Special rules for composing `insert` transformations
  #

  defp transform_op(%{insert: lft_idx},
                    %{insert: idx, init: init}, :left) when idx >= lft_idx do
    insert(idx + 1, init)
  end

  defp transform_op(%{insert: lft_idx, init: lft_init},
                    %{insert: _} = insert, :left) do
    [remove(lft_idx), insert(lft_idx - 1, lft_init), insert]
  end

  defp transform_op(%{insert: ins_idx},
                    %{remove: rem_idx}, _)
  when rem_idx >= ins_idx do
    remove(rem_idx + 1)
  end

  defp transform_op(%{insert: ins_idx},
                    %{replace: rep_idx, init: init}, _)
  when rep_idx >= ins_idx do
    replace(rep_idx + 1, init)
  end

  defp transform_op(%{insert: ins_idx},
                    %{change: chg_idx, delta: delta}, _)
  when chg_idx >= ins_idx do
    change(chg_idx + 1, delta)
  end

  #
  # Special rules for composing `remove` transformations
  #

  defp transform_op(%{remove: rem_idx},
                    %{insert: ins_idx, init: init}, _)
  when ins_idx > rem_idx do
    insert(ins_idx - 1, init)
  end

  defp transform_op(%{remove: idx},
                    %{remove: idx}, _) do
    []
  end

  defp transform_op(%{remove: lft_idx},
                    %{remove: rgt_idx}, _)
  when rgt_idx > lft_idx do
    remove(rgt_idx - 1)
  end

  defp transform_op(%{remove: idx},
                    %{replace: idx, init: init}, _) do
    insert(idx, init)
  end

  defp transform_op(%{remove: rem_idx},
                    %{replace: rep_idx, init: init}, _)
  when rep_idx > rem_idx do
    replace(rep_idx - 1, init)
  end

  defp transform_op(%{remove: rem_idx},
                    %{change: rem_idx}, _) do
    []
  end

  defp transform_op(%{remove: rem_idx},
                    %{change: chg_idx, delta: delta}, _)
  when chg_idx > rem_idx do
    change(chg_idx - 1, delta)
  end

  #
  # Special rules for composing `replace` transformations
  #

  defp transform_op(%{replace: rep_idx},
                    %{remove: rep_idx}, _) do
    []
  end

  defp transform_op(%{replace: rep_idx},
                    %{replace: rep_idx}, :left) do
    []
  end

  defp transform_op(%{replace: rep_idx},
                    %{change: rep_idx}, _) do
    []
  end

  #
  # Special rules for composing `change` transformations
  #

  defp transform_op(%{change: idx, delta: lft_delta},
                    %{change: idx, delta: rgt_delta}, priority) do
    change(idx, ItemDelta.transform(lft_delta, rgt_delta, priority))
  end

  defp transform_op(_lft_op, op, _priority), do: op
end
