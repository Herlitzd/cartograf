defmodule AP do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule BP do
  defstruct aa: nil, bb: nil, cc: nil, dd: nil
end

defmodule PerformanceTest do
  use ExUnit.Case
  use Cartograf
  use Revised

  m AP, BP, :new do
    let(:a, :aa)
    let(:b, :bb)
    let(:c, :cc)
    let(:d, :dd)
  end

  Cartograf.map AP, BP, :old do
    [
      Cartograf.let(:a, :aa),
      Cartograf.let(:b, :bb),
      Cartograf.let(:c, :cc),
      Cartograf.let(:d, :dd)
    ]
  end
  Revised.map AP, BP, :best do
    Revised.let(:a, :aa)
    Revised.let(:b, :bb)
    Revised.let(:c, :cc)
    Revised.let(:d, :dd)
  end

  test "perf" do
    start = Time.utc_now()

    for n <- 0..1_000_000 do
      t = old(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    old_diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("old " <> inspect(old_diff))

    start = Time.utc_now()

    for n <- 0..1_000_000 do
      t = new(%AP{a: 1, b: 2, c: 3, d: 4}, %{})
    end

    new_diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("new " <> inspect(new_diff))
    IO.inspect(new_diff / old_diff)
    start = Time.utc_now()

    for n <- 0..1_000_000 do
      direct(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    raw_diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("raw " <> inspect(raw_diff))

    start = Time.utc_now()

    for n <- 0..1_000_000 do
      best(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    raw_diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("best " <> inspect(raw_diff))

  end

  def direct(str) do
    %BP{aa: str.a, bb: str.b, cc: str.c, dd: str.d}
  end
end
