defmodule AP do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule BP do
  defstruct aa: nil, bb: nil, cc: nil, dd: nil
end

defmodule PerformanceTest do
  use ExUnit.Case
  use Revised

  map AP, BP, :cart do
    let(:a, :aa)
    let(:b, :bb)
    let(:c, :cc)
    let(:d, :dd)
  end

  test "perf" do
    start = Time.utc_now()

    for n <- 0..10_000_000 do
      direct(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    raw_diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("raw " <> inspect(raw_diff) <> "us")

    start = Time.utc_now()

    for n <- 0..10_000_000 do
      cart(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    raw_diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("car " <> inspect(raw_diff) <> "us")
  end

  def direct(str = %AP{}) do
    %BP{aa: str.a, bb: str.b, cc: str.c, dd: str.d}
  end
end
