defmodule AA do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule AB do
  defstruct aa: nil, bb: nil, cc: nil, dd: nil
end

defmodule AC do
  defstruct a: nil, b: nil, c: nil, dd: nil
end

defmodule CartografTest.Advanced do
  use ExUnit.Case
  use Cartograf

  map AA, AB, :simple_nested do
    let(:a, :aa)
    let(:b, :bb)
    let(:c, :cc)
    nest(:dd, AC) do
      let(:a, :a)
      let(:b, :b)
      let(:c, :c)
      let(:d, :dd)
    end
  end

  map AA, AB, :complex_nested do
    let(:a, :aa)
    let(:b, :bb)
    let(:c, :cc)
    nest(:dd, AC) do
      let(:a, :a)
      let(:b, :b)
      let(:c, :c)
      nest(:dd, AB) do
        let(:a, :aa)
        let(:d, :dd)
        let(:c, :cc)
        nest(:bb, AA) do
          let(:a, :a)
          let(:b, :b)
          let(:c, :c)
          let(:d, :d)
        end
      end
    end
  end

  map AA, AB, :with_const do
    let :a, :aa
    drop :b
    const :bb, "abc"
    let :c, :cc
    let :d, :dd
  end
  map AA, AA, :with_missing, auto: true do
    let :a, :a
    drop :c
  end
  map AA, AA, :missing do
    let :a, :a
    drop :c
    drop :b
    drop :d
  end

  map AA, AB, :with_nest do
    let :a, :aa
    const :bb, "abc"
    nest :cc, AA do
      let :a, :a
      let :b, :b
    end
    let :d, :dd
    drop :b
    drop :c
  end


  test "simple nested mapping" do
    t = simple_nested(%AA{a: 1, b: 2, c: 3, d: 4})
    assert %AB{} = t
    assert t.aa == 1
    assert t.bb == 2
    assert t.cc == 3
    assert %AC{} = t.dd
    assert t.dd.a == 1
    assert t.dd.b == 2
    assert t.dd.c == 3
    assert t.dd.dd == 4
  end

  test "complex nested mapping" do
    t = complex_nested(%AA{a: 1, b: 2, c: 3, d: 4})
    assert t.aa == 1
    assert t.bb == 2
    assert t.cc == 3
    assert %AC{} = t.dd
    assert t.dd.a == 1
    assert t.dd.b == 2
    assert t.dd.c == 3
    assert %AB{} = t.dd.dd
    assert t.dd.dd.aa == 1
    assert t.dd.dd.cc == 3
    assert t.dd.dd.dd == 4
    assert %AA{} = t.dd.dd.bb
    assert t.dd.dd.bb.a == 1
    assert t.dd.dd.bb.b == 2
    assert t.dd.dd.bb.c == 3
    assert t.dd.dd.bb.d == 4
  end

  test "with const" do
    p = %AA{a: 1, b: 2, c: 3, d: 4}
    k = with_const(p)
    assert k.aa == 1
    assert k.bb == "abc"
    assert k.cc == 3
    assert k.dd == 4
  end

  test "with nest" do
    p = %AA{a: 1, b: 2, c: 3, d: 4}
    k = with_nest(p)
    assert k.aa == 1
    assert k.bb == "abc"
    assert %AA{} = k.cc
    assert k.cc.a == 1
    assert k.cc.b == 2
    assert k.dd == 4
  end

  test "auto with drop" do
    p = %AA{a: 1, b: 2, c: 3, d: 4}
    k = with_missing(p)
    assert k.a == 1
    assert k.b == 2
    assert k.c == nil
    assert k.d == 4
  end

end
