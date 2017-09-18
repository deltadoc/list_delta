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
      assert comp(fst, snd) == [insert(0, nil), insert(1, 2)]
    end

    test "insert at a lower index maintains both" do
      fst = ListDelta.insert(2, 3)
      snd = ListDelta.insert(0, 5)
      assert comp(fst, snd) == [insert(0, 5), insert(3, 3)]
    end

    test "remove at a different index maintains both" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.remove(4)
      assert comp(fst, snd) == [insert(0, 3), remove(4)]
      assert comp(snd, fst) == [insert(0, 3), remove(5)]
    end

    test "remove at a lower index maintains both" do
      fst = ListDelta.insert(2, 3)
      snd = ListDelta.remove(0)
      assert comp(fst, snd) == [remove(0), insert(1, 3)]
      assert comp(snd, fst) == [remove(0), insert(2, 3)]
    end

    test "remove a the same index drops both operations" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.remove(0)
      assert comp(fst, snd) == []
    end

    test "remove a follow-up index transforms into replace" do
      fst = ListDelta.insert(0, 3)
      snd = ListDelta.remove(1)
      assert comp(fst, snd) == [replace(0, 3)]
      assert comp(snd, fst) == [insert(0, 3), remove(2)]
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
      assert comp(fst, snd) == [insert(0, nil), insert(1, 3)]
    end

    test "2 inserts and a remove at a computed index drops right insert" do
      fst =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(0, nil)
        |> ListDelta.insert(0, false)
      snd = ListDelta.remove(1)
      assert comp(fst, snd) == [insert(0, false), insert(1, 3)]
    end

    test "insert at different position and a remove for the original insert" do
      fst =
        ListDelta.new()
        |> ListDelta.insert(0, 3)
        |> ListDelta.insert(2, nil)
      snd = ListDelta.remove(0)
      assert comp(fst, snd) == [insert(1, nil)]
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
      assert comp(snd, fst) == [insert(0, 3), replace(3, "text")]
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
      assert comp(snd, fst) == [insert(0, 3), change(3, "text")]
    end
  end

  describe "remove +" do
    @fst ListDelta.remove(1)

    test "insert at the same index changes insert into replace" do
      snd = ListDelta.insert(1, "text")
      assert comp(@fst, snd) == [replace(1, "text")]
    end

    test "insert at a higher index maintains both" do
      snd = ListDelta.insert(3, "text")
      assert comp(@fst, snd) == [remove(1), insert(3, "text")]
      assert comp(snd, @fst) == [remove(1), insert(2, "text")]
    end

    test "insert at a lower index maintains both" do
      snd = ListDelta.insert(0, "text")
      assert comp(@fst, snd) == [insert(0, "text"), remove(2)]
      assert comp(snd, @fst) == [replace(0, "text")]
    end

    test "change at the same index maintains both" do
      snd = ListDelta.change(1, "text")
      assert comp(@fst, snd) == [remove(1), change(1, "text")]
      assert comp(snd, @fst) == [remove(1)]
    end

    test "change at a higher index maintains both" do
      snd = ListDelta.change(3, "text")
      assert comp(@fst, snd) == [remove(1), change(3, "text")]
      assert comp(snd, @fst) == [remove(1), change(2, "text")]
    end

    test "remove at the same index maintains both" do
      snd = ListDelta.remove(1)
      assert comp(@fst, snd) == [remove(1), remove(1)]
      assert comp(snd, @fst) == [remove(1), remove(1)]
    end

    test "remove at a different index maintains both" do
      snd = ListDelta.remove(2)
      assert comp(@fst, snd) == [remove(1), remove(2)]
      assert comp(snd, @fst) == [remove(1), remove(1)]
    end

    test "replace at the same index maintains both" do
      snd = ListDelta.replace(1, 5)
      assert comp(@fst, snd) == [remove(1), replace(1, 5)]
      assert comp(snd, @fst) == [remove(1)]
    end

    test "replace at a higher index maintains both" do
      snd = ListDelta.replace(3, 5)
      assert comp(@fst, snd) == [remove(1), replace(3, 5)]
      assert comp(snd, @fst) == [remove(1), replace(2, 5)]
    end
  end

  describe "replace +" do
    @fst ListDelta.replace(0, 123)

    test "insert at the same index maintains both" do
      snd = ListDelta.insert(0, "text")
      assert comp(@fst, snd) == [replace(0, 123), insert(0, "text")]
    end

    test "insert at a higher index maintains both" do
      snd = ListDelta.insert(3, "text")
      assert comp(@fst, snd) == [replace(0, 123), insert(3, "text")]
      assert comp(snd, @fst) == [replace(0, 123), insert(3, "text")]
    end

    test "change at the same index updates replace init" do
      snd = ListDelta.change(0, "text")
      assert comp(@fst, snd) == [replace(0, "text")]
    end

    test "change at a different index maintains both" do
      snd = ListDelta.change(1, "text")
      assert comp(@fst, snd) == [replace(0, 123), change(1, "text")]
      assert comp(snd, @fst) == [replace(0, 123), change(1, "text")]
    end

    test "remove at the same index removes replace" do
      snd = ListDelta.remove(0)
      assert comp(@fst, snd) == [remove(0)]
    end

    test "remove at a different index maintains both" do
      snd = ListDelta.remove(1)
      assert comp(@fst, snd) == [replace(0, 123), remove(1)]
      assert comp(snd, @fst) == [replace(0, 123), remove(1)]
    end

    test "replace at the same index removes first replace" do
      snd = ListDelta.replace(0, 5)
      assert comp(@fst, snd) == [replace(0, 5)]
      assert comp(snd, @fst) == [replace(0, 123)]
    end

    test "replace at a different index maintains both" do
      snd = ListDelta.replace(1, 5)
      assert comp(@fst, snd) == [replace(0, 123), replace(1, 5)]
    end
  end

  describe "change +" do
    @fst ListDelta.change(0, "abc")

    test "insert at the same index maintains both" do
      snd = ListDelta.insert(0, "text")
      assert comp(@fst, snd) == [change(0, "abc"), insert(0, "text")]
    end

    test "insert at a different index maintains both" do
      snd = ListDelta.insert(2, "text")
      assert comp(@fst, snd) == [change(0, "abc"), insert(2, "text")]
      assert comp(snd, @fst) == [change(0, "abc"), insert(2, "text")]
    end

    test "change at the same index composes changes" do
      snd = ListDelta.change(0, "text")
      assert comp(@fst, snd) == [change(0, "text")]
    end

    test "change at a different index maintains both" do
      snd = ListDelta.change(1, "text")
      assert comp(@fst, snd) == [change(0, "abc"), change(1, "text")]
      assert comp(snd, @fst) == [change(0, "abc"), change(1, "text")]
    end

    test "remove at the same index drops change" do
      snd = ListDelta.remove(0)
      assert comp(@fst, snd) == [remove(0)]
    end

    test "remove at a different index maintains both" do
      snd = ListDelta.remove(1)
      assert comp(@fst, snd) == [change(0, "abc"), remove(1)]
      assert comp(snd, @fst) == [change(0, "abc"), remove(1)]
    end

    test "replace at the same index drops change" do
      snd = ListDelta.replace(0, 5)
      assert comp(@fst, snd) == [replace(0, 5)]
    end

    test "replace at a different index maintains both" do
      snd = ListDelta.replace(1, 5)
      assert comp(@fst, snd) == [change(0, "abc"), replace(1, 5)]
      assert comp(snd, @fst) == [change(0, "abc"), replace(1, 5)]
    end
  end

  describe "normalisation" do
    test "inserts are ordered by index" do
      result =
        ListDelta.new()
        |> ListDelta.compose(ListDelta.insert(5, "text"))
        |> ListDelta.compose(ListDelta.insert(2, false))
        |> ListDelta.compose(ListDelta.insert(3, 5))
        |> ListDelta.compose(ListDelta.insert(1, nil))
        |> ListDelta.operations()
      assert result == [
        insert(1, nil),
        insert(3, false),
        insert(4, 5),
        insert(8, "text")
      ]
    end

    test "removes are ordered by index" do
      result =
        ListDelta.new()
        |> ListDelta.compose(ListDelta.remove(5))
        |> ListDelta.compose(ListDelta.remove(2))
        |> ListDelta.compose(ListDelta.remove(3))
        |> ListDelta.compose(ListDelta.remove(1))
        |> ListDelta.operations()
      assert result == [
        remove(1),
        remove(1),
        remove(2),
        remove(2)
      ]
    end

    test "replaces are ordered by index" do
      result =
        ListDelta.new()
        |> ListDelta.compose(ListDelta.replace(5, "text"))
        |> ListDelta.compose(ListDelta.replace(2, false))
        |> ListDelta.compose(ListDelta.replace(3, 5))
        |> ListDelta.compose(ListDelta.replace(1, nil))
        |> ListDelta.operations()
      assert result == [
        replace(1, nil),
        replace(2, false),
        replace(3, 5),
        replace(5, "text")
      ]
    end

    test "changes are ordered by index" do
      result =
        ListDelta.new()
        |> ListDelta.compose(ListDelta.change(5, "text"))
        |> ListDelta.compose(ListDelta.change(2, false))
        |> ListDelta.compose(ListDelta.change(3, 5))
        |> ListDelta.compose(ListDelta.change(1, nil))
        |> ListDelta.operations()
      assert result == [
        change(1, nil),
        change(2, false),
        change(3, 5),
        change(5, "text")
      ]
    end
  end

  defp comp(first, second) do
    first
    |> ListDelta.compose(second)
    |> ListDelta.operations()
  end
end
