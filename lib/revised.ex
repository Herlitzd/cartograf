defmodule Revised do

  defmacro __using__(_) do
    quote do
      import Revised
    end
  end
  defp get_children({:__block__, _meta, elements}) do
    elements
  end

  defp get_children(element) do
    [element]
  end
  defp tokenize(children) do
    Enum.reduce(children, %{}, fn {atm, tup}, acc ->
      IO.inspect(tup)
      Map.update(acc, atm, [tup], fn val -> [tup | val] end)
    end)
  end
  defp make_struct_from_module(module) do
    {s, _} = Code.eval_quoted(quote do: %unquote(module){})
    s
  end

  defp make_map ({lets, to}) do
    k = Enum.reduce(lets, [], fn {f,t}, acc ->
      [{t, quote do: from.unquote(f)} | acc]
    end)
    quote do
      %unquote(to){unquote(k)}

    end
    {:%,[], [to, {:%{}, [], k}]}
  end

  defp map_internal(from_t, to_t, name, auto?, children) do
    mappings = tokenize(children)
    s = make_struct_from_module(from_t)
    p = make_map({mappings[:let], to_t})
    IO.inspect(p)
    quote do
      def unquote(:"#{name}")(from = %unquote(from_t){}, to \\ %unquote(to_t){}) do
        unquote(p)
      end
    end
  end

  #  @spec m(module(), module(), atom, [], do: any()) :: any()
  defmacro map(from_t, to_t, name, opts \\ [], do: block) do
    children = get_children(block)

    children =
      Macro.prewalk(children, fn k ->
        Macro.expand(k, __ENV__)
      end)

    auto? = Keyword.get(opts, :auto, true)

    map_internal(from_t, to_t, name, auto?, children)
  end


  @doc """
  Specify where the a field in the input should be mapped to
  in the out.
  """
  @spec let(atom(), atom()) :: any()
  defmacro let(source_key, dest_key) do
    {:let, {source_key, dest_key}}
  end
end
