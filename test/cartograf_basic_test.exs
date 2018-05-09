defmodule A do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule B do
  defstruct aa: nil, bb: nil, cc: nil, dd: nil
end

defmodule C do
  defstruct a: nil, b: nil, c: nil, dd: nil
end

defmodule(D, do: defstruct([:a, :b, :c, :d, :e]))

defmodule CartografTest.Basic do
  use ExUnit.Case
  use Cartograf

  map A, B, :one_to_one do
    [
      let(:a, :aa),
      let(:b, :bb),
      let(:c, :cc),
      let(:d, :dd)
    ]
  end

  map A, C, :auto_but_one do
    [
      let(:d, :dd)
    ]
  end

  map A, C, :auto_with_drop do
    [
      drop(:d)
    ]
  end

  map D, A, :unmapped_field do
    []
  end

  map A, A, :a_to_a, auto: false do
    []
  end
  map A, C, :with_const do
    [
      # We must :a here because
      # it will not be auto bound
      # as doing so would overrite
      # the const field
      const(:a, "Hello"),
      let(:d, :dd),
      drop(:a)
    ]
  end

  test "one to one mapping" do
    t = one_to_one(%A{a: 1, b: 2, c: 3, d: 4})
    assert %B{} = t
    assert t.aa == 1
    assert t.bb == 2
    assert t.cc == 3
    assert t.dd == 4
  end

  test "all auto mapped except one" do
    t = auto_but_one(%A{a: 1, b: 2, c: 3, d: 4})
    assert %C{} = t
    assert t.a == 1
    assert t.b == 2
    assert t.c == 3
    assert t.dd == 4
  end

  test "all auto with a drop" do
    t = auto_with_drop(%A{a: 1, b: 2, c: 3, d: 4})
    assert %C{} = t
    assert t.a == 1
    assert t.b == 2
    assert t.c == 3
    assert t.dd == nil
  end

  test "unmapped field" do
    t = %D{a: 1, b: 2, c: 3, d: 4, e: 5}

    assert_raise Cartograf.MappingException, fn ->
      unmapped_field(t)
    end

    assert catch_error(unmapped_field(t)).message =~ "not mapped: e"
  end

  test "method not found" do
    t = %D{a: 1, b: 2, c: 3, d: 4, e: 5}
    assert_raise FunctionClauseError, fn -> one_to_one(t) end
  end

  test "non-auto failure" do
    t = %A{a: 1, b: 2, c: 3, d: 4}
    assert_raise Cartograf.MappingException, fn ->
      a_to_a(t)
    end
  end
  test "const use" do
    t = with_const(%A{a: 1, b: 2, c: 3, d: 4})
    assert %C{} = t
    assert t.a == "Hello"
    assert t.b == 2
    assert t.c == 3
    assert t.dd == 4
  end

end
