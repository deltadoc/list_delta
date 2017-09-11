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

  defp transform_op(%{insert: lft_idx},
                    %{remove: idx}, :right) when idx >= lft_idx do
    remove(idx + 1)
  end

  defp transform_op(%{insert: lft_idx},
                    %{replace: idx, init: init}, :right) when idx >= lft_idx do
    replace(idx + 1, init)
  end

  defp transform_op(%{insert: lft_idx},
                    %{move: idx, to: to_idx}, :right) when idx >= lft_idx do
    move(idx + 1, to_idx + 1)
  end

  defp transform_op(%{remove: lft_idx},
                    %{insert: idx, init: init}, _) when idx > lft_idx do
    insert(idx - 1, init)
  end

  defp transform_op(_lft_op, op, _priority), do: op
end
