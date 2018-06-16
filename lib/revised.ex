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
      Map.update(acc, atm, [tup], fn val -> [tup | val] end)
    end)
  end
  defp get_list(lst, atom) do
    Map.get(lst, atom, [])
  end

  defp make_map({bindings, to, bound_var}) do
    to_keys = []
    bound = Macro.var(bound_var, __MODULE__)
    const_mapping =
      Enum.reduce(get_list(bindings, :const), [], fn {t, v}, acc ->
        [{t, v} | acc]
      end)
    let_mapping =
      Enum.reduce(get_list(bindings, :let), [], fn {f, t}, acc ->
        [{t, quote(do: unquote(bound).unquote(f))} | acc]
      end)


    merged_mapping = let_mapping ++ const_mapping
    {:%, [], [to, {:%{}, [], merged_mapping}]}
  end

  defp random_id do
    String.to_atom(Integer.to_string(:rand.uniform(4294967296), 32))
  end
  defp map_internal(children, to_t, binding) do
    children =
      Macro.prewalk(children, fn mappings ->
        mappings = Macro.expand(mappings, __ENV__)
        case mappings do
          {:nest, {key, nest_fn}} -> {:const, {key, nest_fn.(binding)}}
          k -> k
        end
      end)
    # IO.inspect(children)
    mappings = tokenize(children)
    # IO.inspect(mappings)
    make_map({mappings, to_t, binding})
  end

  defp map_p(from_t, to_t, name, auto?, children) do
    binding = random_id()
    created_map = map_internal(children, to_t, binding)

    binding = Macro.var(binding, __MODULE__)
    quote do
      def unquote(:"#{name}")(unquote(binding) = %unquote(from_t){}, to \\ %unquote(to_t){}) do
        unquote(created_map)
      end
    end
  end

  #  @spec m(module(), module(), atom, [], do: any()) :: any()
  defmacro map(from_t, to_t, name, opts \\ [], do: block) do
    children = get_children(block)

    # children =
    #   Macro.prewalk(children, fn mappings ->
    #     Macro.expand(mappings, __ENV__)
    #   end)

    auto? = Keyword.get(opts, :auto, true)

    map_p(from_t, to_t, name, auto?, children)
  end

  @doc """
  Specify where the a field in the input should be mapped to
  in the out.
  """
  @spec let(atom(), atom()) :: any()
  defmacro let(source_key, dest_key) do
    {:let, {source_key, dest_key}}
  end

  @spec const(atom(), any()) :: any()
  defmacro const(dest_key, val) do
    {:const, {dest_key, val}}
  end

  @spec nest(atom(), module(), do: any()) :: any()
  defmacro nest(dest_key, to_t, do: block) do
    children = get_children(block)

    # children =
    #   Macro.prewalk(children, fn mappings ->
    #     Macro.expand(mappings, __ENV__)
    #   end)
    nest_scope = fn(binding) -> map_internal(children, to_t, binding) end

    {:nest, {dest_key, nest_scope}}
  end

  @spec drop(atom()) :: any()
  defmacro drop(src_key) do
    {:drop, {src_key}}
  end
end
