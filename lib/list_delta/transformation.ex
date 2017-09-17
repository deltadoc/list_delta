defmodule ListDelta.Transformation do
  alias ListDelta.{Operation}

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

  defp transform_op(%{insert: lft_idx},
                    %{insert: idx, init: init}, :left) when idx >= lft_idx do
    insert(idx + 1, init)
  end

  defp transform_op(%{insert: lft_idx},
                    %{insert: _} = insert, :left) do
    [move(lft_idx, lft_idx - 1), insert]
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

  defp transform_op(%{insert: ins_idx},
                    %{move: from_idx, to: to_idx}, _)
  when from_idx < ins_idx and to_idx >= ins_idx do
    [move(from_idx, to_idx + 1), move(ins_idx - 1, ins_idx)]
  end

  defp transform_op(%{insert: ins_idx},
                    %{move: from_idx, to: to_idx}, _)
  when from_idx >= ins_idx and to_idx < ins_idx do
    [move(from_idx + 1, to_idx), move(ins_idx, ins_idx + 1)]
  end

  defp transform_op(%{insert: ins_idx},
                    %{move: from_idx, to: to_idx}, _)
  when from_idx >= ins_idx do
    move(from_idx + 1, to_idx + 1)
  end

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

  defp transform_op(%{remove: idx},
                    %{move: idx}, _) do
    []
  end

  defp transform_op(%{remove: idx},
                    %{move: from_idx, to: idx}, _)
  when from_idx > idx do
    move(from_idx - 1, idx)
  end

  defp transform_op(%{remove: rem_idx},
                    %{move: from_idx, to: to_idx}, _)
  when from_idx < rem_idx and rem_idx < to_idx do
    move(from_idx, to_idx - 1)
  end

  defp transform_op(%{remove: rem_idx},
                    %{move: from_idx, to: to_idx}, _)
  when to_idx < rem_idx and rem_idx < from_idx do
    move(from_idx - 1, to_idx)
  end

  defp transform_op(%{remove: idx},
                    %{move: from_idx, to: to_idx}, _)
  when from_idx > idx and to_idx > idx do
    move(from_idx - 1, to_idx - 1)
  end

  defp transform_op(%{remove: idx},
                    %{move: from_idx, to: idx}, _)
  when from_idx < idx do
    move(from_idx, idx - 1)
  end

  defp transform_op(%{move: from_idx, to: to_idx},
                    %{remove: rem_idx}, _)
  when from_idx < rem_idx and rem_idx < to_idx do
    remove(rem_idx - 1)
  end

  defp transform_op(%{move: from_idx, to: to_idx},
                    %{remove: rem_idx}, _)
  when to_idx < rem_idx and rem_idx < from_idx do
    remove(rem_idx + 1)
  end

  defp transform_op(%{move: idx, to: to_idx},
                    %{remove: idx}, _) do
    remove(to_idx)
  end

  defp transform_op(%{move: idx, to: to_idx},
                    %{remove: idx}, _) do
    remove(to_idx)
  end

  defp transform_op(%{move: from_idx, to: idx},
                    %{remove: idx}, _)
  when from_idx > idx do
    remove(idx + 1)
  end

  defp transform_op(%{move: from_idx, to: idx},
                    %{remove: idx}, _)
  when from_idx < idx do
    remove(idx - 1)
  end

  defp transform_op(%{replace: idx},
                    %{remove: idx}, _) do
    []
  end

  defp transform_op(_lft_op, op, _priority), do: op
end
