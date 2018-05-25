
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
  test "rev" do
    p = %AR{a: 1, b: 2, c: 3, d: 4}
    k = revised(p)
    assert k.aa == 1
    assert k.bb == 2
    assert k.cc == 3
    assert k.dd == 4
  end

end
