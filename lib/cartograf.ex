defmodule Cartograf do
  require IEx

  defmacro __using__(_) do
    quote do
      import Cartograf
      Module.register_attribute(__MODULE__, :already_set, accumulate: true)
    end
  end

  defmacro map(from_t, to_t, name, do: block) do
    module = __CALLER__.module
    # IO.inspect(Module.get_attribute(module, :already_set))

    quote do
      def unquote(:"#{name}")(from = %unquote(from_t){}) do
        Enum.reduce(unquote(block), %unquote(to_t){}, fn fields, acc ->
          fields.(from, acc)
        end)
      end
    end
  end

  defmacro let(source_key, dest_key) do
    module = __CALLER__.module
    # Module.put_attribute(module, :already_set, source_key)
    # IO.inspect(Module.get_attribute(module, :already_set))
    quote do
      fn from, to ->
        Map.put(to, unquote(dest_key), Map.get(from, unquote(source_key)))
      end
    end
  end
end

defmodule Example do
  use Cartograf
  require IEx

  map(Ex.A, Ex.B, :a_to_b) do
    [
      let(:a, :AA),
      let(:b, :b),
      let(:c, :c),
      let(:D, :d)
    ]
  end

  def test() do
    a = %Ex.A{a: "a", b: "b", c: "c", D: "d"}
    a_to_b(a)
  end
end
