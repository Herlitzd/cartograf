defmodule Fancy do
  defp get_children({:__block__, _meta, elements}) do
    elements
  end

  defp get_children(element) do
    [element]
  end

  defmacro fancy(do: block) do
    children = get_children(block)

    p =
      Macro.prewalk(children, fn k ->
        Macro.expand(k, __ENV__)
      end)

    quote do
      def unquote(:a)(from) do
        Enum.reduce(unquote(p), %{}, fn fnct, acc -> fnct.(from, acc) end)
      end
    end

    # Macro.prewalk(children, fn k -> IO.inspect(Macro.expand(k, __ENV__), label: "prewalk") end)
  end

  defmacro shiny(f, t) do
    quote do
      fn from, to ->
        Map.put(to, unquote(t), Map.get(from, unquote(f)))
      end
    end
  end
end
