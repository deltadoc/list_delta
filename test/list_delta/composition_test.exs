defmodule ListDelta.CompositionTest do
  use ExUnit.Case
  use EQC.ExUnit

  import ListDelta.Operation
  import ListDelta.Generators

  doctest ListDelta.Composition

  property "(a + b) + c = a + (b + c)" do
    forall {delta_a, delta_b} <- {delta(), delta()} do
      list = ListDelta.new()
      list_a = ListDelta.compose(list, delta_a)
      list_b = ListDelta.compose(list_a, delta_b)

      delta_c = ListDelta.compose(delta_a, delta_b)
      list_c = ListDelta.compose(list, delta_c)

      ensure list_b == list_c
    end
  end

  describe "insert +" do
    test "insert at a different index maintains both" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.insert(2, false)
      assert comp(fst, snd) == [insert(0, 3), insert(2, false)]
    end

    test "insert at the same index maintains both" do
      fst = ListDelta.insert(0, 2)
      snd = ListDelta.insert(0, nil)
      assert comp(fst, snd) == [insert(0, 2), insert(0, nil)]
    end

    test "insert at a lower index maintains both" do
      fst = ListDelta.insert(2, 3)
      snd = ListDelta.insert(0, 5)
      assert comp(fst, snd) == [insert(2, 3), insert(0, 5)]
    end

    test "remove at a different index maintains both" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.remove(4)
      assert comp(fst, snd) == [remove(3), insert(0, 3)]
    end

    test "remove a the same index drops both operations" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.remove(0)
      assert comp(fst, snd) == []
    end

    test "insert and a remove at the same index drops second insert" do
      fst =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
      snd = ListDelta.remove(0)
      assert comp(fst, snd) == [insert(0, 3)]
    end

    test "2 inserts and a remove at the same index drops third insert" do
      fst =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
        |> ListDelta.insert(0, false)
      snd = ListDelta.remove(0)
      assert comp(fst, snd) == [insert(0, 3), insert(0, nil)]
    end

    test "2 inserts and a remove at a different index keeps all ops" do
      fst =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
        |> ListDelta.insert(0, false)
      snd = ListDelta.remove(1)
      assert comp(fst, snd) == [insert(0, 3), insert(0, false)]
    end

    test "replace at the same index changes the insert init" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.replace(0, "text")
      assert comp(fst, snd) == [insert(0, "text")]
    end

    test "replace at a different index maintains both" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.replace(2, "text")
      assert comp(fst, snd) == [insert(0, 3), replace(2, "text")]
    end

    test "change at the same index updates the insert init" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.change(0, 6)
      assert comp(fst, snd) == [insert(0, 6)]
    end

    test "change at a different index maintains both" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.change(2, "text")
      assert comp(fst, snd) == [insert(0, 3), change(2, "text")]
    end
  end

  describe "remove +" do
    @fst ListDelta.remove(1)

    test "insert at the same index changes insert into replace" do
      snd = ListDelta.insert(1, "text")
      assert comp(@fst, snd) == [replace(1, "text")]
    end

    test "insert at a higher index maintains both" do
      snd = ListDelta.insert(2, "text")
      assert comp(@fst, snd) == [remove(1), insert(2, "text")]
    end

    test "insert at a lower index maintains both" do
      snd = ListDelta.insert(0, "text")
      assert comp(@fst, snd) == [remove(1), insert(0, "text")]
    end

    test "change maintains both" do
      snd = ListDelta.change(1, "text")
      assert comp(@fst, snd) == [remove(1), change(1, "text")]
    end

    test "remove at the same index drops second remove" do
      snd = ListDelta.remove(1)
      assert comp(@fst, snd) == [remove(1)]
    end

    test "remove at a different index maintains both" do
      snd = ListDelta.remove(2)
      assert comp(@fst, snd) == [remove(1), remove(2)]
    end

    test "replace maintains both" do
      snd = ListDelta.replace(1, 5)
      assert comp(@fst, snd) == [remove(1), replace(1, 5)]
    end
  end

  describe "replace +" do
    @fst ListDelta.replace(0, 123)

    test "insert maintains both" do
      snd = ListDelta.insert(0, "text")
      assert comp(@fst, snd) == [replace(0, 123), insert(0, "text")]
    end

    test "change at the same index updates replace init" do
      snd = ListDelta.change(0, "text")
      assert comp(@fst, snd) == [replace(0, "text")]
    end

    test "change at a different index maintains both" do
      snd = ListDelta.change(1, "text")
      assert comp(@fst, snd) == [replace(0, 123), change(1, "text")]
    end

    test "remove at the same index removes replace" do
      snd = ListDelta.remove(0)
      assert comp(@fst, snd) == [remove(0)]
    end

    test "remove at a different index maintains both" do
      snd = ListDelta.remove(1)
      assert comp(@fst, snd) == [replace(0, 123), remove(1)]
    end

    test "replace at the same index removes first replace" do
      snd = ListDelta.replace(0, 5)
      assert comp(@fst, snd) == [replace(0, 5)]
    end

    test "replace at a different index maintains both" do
      snd = ListDelta.replace(1, 5)
      assert comp(@fst, snd) == [replace(0, 123), replace(1, 5)]
    end
  end

  describe "change +" do
    @fst ListDelta.change(0, "abc")

    test "insert maintains both" do
      snd = ListDelta.insert(0, "text")
      assert comp(@fst, snd) == [change(0, "abc"), insert(0, "text")]
    end

    test "change at the same index composes changes" do
      snd = ListDelta.change(0, "text")
      assert comp(@fst, snd) == [change(0, "text")]
    end

    test "change at a different index maintains both" do
      snd = ListDelta.change(1, "text")
      assert comp(@fst, snd) == [change(0, "abc"), change(1, "text")]
    end

    test "remove at the same index drops change" do
      snd = ListDelta.remove(0)
      assert comp(@fst, snd) == [remove(0)]
    end

    test "remove at a different index maintains both" do
      snd = ListDelta.remove(1)
      assert comp(@fst, snd) == [change(0, "abc"), remove(1)]
    end

    test "replace at the same index drops change" do
      snd = ListDelta.replace(0, 5)
      assert comp(@fst, snd) == [replace(0, 5)]
    end

    test "replace at a different index maintains both" do
      snd = ListDelta.replace(1, 5)
      assert comp(@fst, snd) == [change(0, "abc"), replace(1, 5)]
    end
  end

  describe "normalisation" do
    test "inserts always come last" do
      ins = insert(0, 1)
      dlt = ListDelta.new([ins])
      assert ListDelta.remove(3) |> comp(dlt) |> Enum.at(1) == ins
      assert ListDelta.replace(3, "B") |> comp(dlt) |> Enum.at(1) == ins
      assert ListDelta.change(3, "B") |> comp(dlt) |> Enum.at(1) == ins
    end

    test "removes always come second to last" do
      rem = remove(0)
      dlt = ListDelta.new([rem])
      assert ListDelta.insert(1, 1) |> comp(dlt) |> Enum.at(0) == rem
      assert ListDelta.replace(3, "B") |> comp(dlt) |> Enum.at(1) == rem
      assert ListDelta.change(3, "B") |> comp(dlt) |> Enum.at(1) == rem
    end
  end

  defp comp(first, second) do
    first
    |> ListDelta.compose(second)
    |> ListDelta.operations()
  end
end
