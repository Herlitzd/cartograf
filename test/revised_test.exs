
defmodule AR do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule BR do
  defstruct aa: nil, bb: nil, cc: nil, dd: nil
end

defmodule RevisedTest do
  use ExUnit.Case
  use Revised

  map AR, BR, :revised do
    let :a, :aa
    let :b, :bb
    let :c, :cc
    let :d, :dd
  end
  map AR, BR, :with_const do
    let :a, :aa
    const :bb, "abc"
    let :c, :cc
    let :d, :dd
  end
  map AR, AR, :with_missing, auto: true do
    let :a, :a
    drop :c
  end
  map AR, AR, :missing do
    let :a, :a
    drop :c
  end

  map AR, BR, :with_nest do
    let :a, :aa
    const :bb, "abc"
    nest :cc, AR do
      let :a, :a
      let :b, :b
    end
    let :d, :dd
  end
  test "rev" do
    p = %AR{a: 1, b: 2, c: 3, d: 4}
    k = revised(p)
    assert k.aa == 1
    assert k.bb == 2
    assert k.cc == 3
    assert k.dd == 4
  end
  test "revised with const" do
    p = %AR{a: 1, b: 2, c: 3, d: 4}
    k = with_const(p)
    assert k.aa == 1
    assert k.bb == "abc"
    assert k.cc == 3
    assert k.dd == 4
  end

  test "revised with nest" do
    p = %AR{a: 1, b: 2, c: 3, d: 4}
    k = with_nest(p)
    assert k.aa == 1
    assert k.bb == "abc"
    assert %AR{} = k.cc
    assert k.cc.a == 1
    assert k.cc.b == 2
    assert k.dd == 4
  end

  test "revised with auto" do
    p = %AR{a: 1, b: 2, c: 3, d: 4}
    k = with_missing(p)
    assert k.a == 1
    assert k.b == 2
    assert k.c == nil
    assert k.d == 4
  end
end
