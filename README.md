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
      let(:a, :a)
      let(:b, :b)
      let(:d, :d)
      const(:e, "constant value")
      let(:cc, :c)
  end
  # auto mapping can be turned on
  map A, B, :a_to_b, auto: true do
    let(:cc, :c) # only need to map keys that don't match
    drop(:e) # drop fields that won't map to avoid warnings
  end
end
```
### Invoking Mapping Functions
```elixir
iex> YourModule.a_to_b(%A{a: 1, b: 2, c: 3, d: 4})
%B{a: 1, b: 2, c: 3, d: 4, e: nil}
```

### Settings

You can configure how cartograf warns you about poorly constructed maps. `:warn` is the
default value for cartograf, and will result in warning about unmapped fields being logged
at compile time. `:throw` will of course cause compilation to fail when keys are unmapped.
Lastly, `:ignore` will not notify about unmapped fields in any way.
``` elixir
# You can configure your application as:
config :cartograf, on_missing_key: :warn
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
    {:cartograf, "~> 0.2.0"} # newest version
    # or
    {:cartograf, git: "https://github.com/Herlitzd/cartograf.git"}
  ]
end
```
