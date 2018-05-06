defmodule CartografTest do
  use ExUnit.Case
  require Cartograf
  alias Cartograf

  doctest Cartograf

  test "greets the world" do
    assert Cartograf.hello() == :world
  end

  test "one to one mapping" do
    Cartograf.map Cartograf.Test.A, Cartograf.Test.B, name, opts \\ [] do
      let(source_key, dest_key)
    end
  end
end

defmodule Cartograf.Test.A do
  defstruct a: nil, b: nil, c: nil, d: nil
end

defmodule Cartograf.Test.B do
  defstruct AA: nil, BB: nil, CC: nil, DD: nil
end

defmodule Cartograf.Test.C do
  defstruct a: nil, b: nil, c: nil, d: nil, e: nil
end

defmodule Cartograf.Test.D do
  defstruct AA: nil, b: nil, c: nil, DD: nil, e: nil
end
