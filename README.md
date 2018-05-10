# Cartograf
[![Build Status](https://travis-ci.org/Herlitzd/cartograf.svg?branch=master)](https://travis-ci.org/Herlitzd/cartograf)
## Struct-to-Struct Mapping Utility for Elixir
*This Project is still under development, and may not be safe for production.*

Documentation can be found at [https://hexdocs.pm/cartograf](https://hexdocs.pm/cartograf).

### Building Mapping Functions
```elixir
defmodule A, do: defstruct [:a, :b, :cc, :d]
defmodule B, do: defstruct [:a, :b, :c, :d, :e]

defmodule YourModule do
use Cartograf

  map A, B, :a_to_b do
    [
      # No need to directly map identical keys, i.e. 
      # let(:a, :a)
      let(:cc, :c)
    ]
  end
  # auto mapping can be turned off
  map A, B, :a_to_b, auto: false do
    ...
  end

  map B, A, :b_to_a do
    [
      # Keys that shouldn't be mapped can be dropped
      drop(:e)
    ]
  end
end
```
### Invoking Mapping Functions
```elixir
iex> YourModule.a_to_b(%A{a: 1, b: 2, c: 3, d: 4})
%B{a: 1, b: 2, c: 3, d: 4, e: nil}
```
## List of Forms
For more information, please look at the docs and tests.

* `map(from_module, to_module, name_of_fn, opts) do ...`\
  Setup a new mapping function
* `let(from_symbol, to_symbol)`\
  Set field to field mapping
* `drop(from_symbol)`\
  Prevent a source field from being mapped
* `const(to_symbol, value)`\
  Provide a constant value for a destination field
* `nest(nested_module, dest_key) do ...`\
  Specify a nested struct type, and a destination field for it.


## Installation

The package can be installed
by adding `cartograf` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cartograf, "~> 0.1.0"}
    # or
    {:cartograf, git: "https://github.com/Herlitzd/cartograf.git"}
  ]
end
```
