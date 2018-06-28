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
end
