defmodule AP do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule BP do
  defstruct aa: nil, bb: nil, cc: nil, dd: nil
end

defmodule PerformanceTest do
  use ExUnit.Case
  use Cartograf

  map AP, BP, :cart do
    let(:a, :aa)
    let(:b, :bb)
    let(:c, :cc)
    let(:d, :dd)
  end

  def native(str = %AP{}) do
    %BP{aa: str.a, bb: str.b, cc: str.c, dd: str.d}
  end
  # Only needed for performance validation
  @tag :skip
  test "perf" do
    start = Time.utc_now()

    for _ <- 0..10_000_000 do
      native(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("native " <> inspect(diff) <> "us")

    start = Time.utc_now()

    for _ <- 0..10_000_000 do
      cart(%AP{a: 1, b: 2, c: 3, d: 4})
    end

    diff = Time.diff(Time.utc_now(), start, :microsecond)
    IO.puts("car " <> inspect(diff) <> "us")
  end

end
