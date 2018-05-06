# Cartograf
[![Build Status](https://travis-ci.org/Herlitzd/cartograf.svg?branch=master)](https://travis-ci.org/Herlitzd/cartograf)
## Struct-to-Struct Mapping Utility for Elixir

```
defmodule A, do: defstruct [:a, :b, :cc, :d]
defmodule B, do: defstruct [:a, :b, :c, :d, :e]

defmodule YourMod do
use Cartograf

  map A, B, name: :a_to_b do
    [
      # No need to directly map identical keys, i.e. 
      # let(:a, :a)
      let(:cc, :c)
    ]
  end
  # auto mapping can be turned off
  map A, B, name: :a_to_b, auto: false do
    ...
  end

  map B, A, name: :b_to_a do
    [
      # Keys that shouldn't be mapped can be dropped
      drop(:e)
    ]
  end
end

```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cartograf` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cartograf, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/cartograf](https://hexdocs.pm/cartograf).

