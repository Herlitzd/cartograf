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

  defp make_struct_map({bindings, to, bound_var}) do
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
    String.to_atom(Integer.to_string(:rand.uniform(4_294_967_296), 32))
  end

  defp verify_mappings(mapped_keys, from_keys) do
    not_mapped = Enum.filter(from_keys, fn key -> not (key in mapped_keys) and key != :__struct__ end)
    IO.inspect(not_mapped)
    if(not Enum.empty?(not_mapped)) do
      raise Cartograf.MappingException, message: "not mapped: #{inspect(not_mapped)}"
    end
  end

  defp map_internal(children, to_t, binding, auto?, from_t \\ nil) do
    children =
      Macro.prewalk(children, fn mappings ->
        mappings = Macro.expand(mappings, __ENV__)

        case mappings do
          {:nest, {key, nest_fn}} -> {:const, {key, nest_fn.(binding)}}
          other -> other
        end
      end)

    mappings = tokenize(children)
    # Get keys that are already mapped
    mapped =
      Keyword.keys(get_list(mappings, :let)) ++ Enum.map(get_list(mappings, :drop), &elem(&1, 0))

    if(auto?) do
      to_atoms = Map.keys(struct(to_t))
      from_atoms = Map.keys(struct(from_t))
      # Get shared keys between to and from
      shared = Enum.filter(to_atoms, fn key -> key in from_atoms end)
      # Get shared keys that are not mapped
      shared = Enum.filter(shared, fn key -> not (key in mapped) && key != :__struct__ end)
      # Add let entries for missing shared keys
      mappings =
        Map.update(mappings, :let, [], fn val ->
          Keyword.merge(val, Enum.map(shared, fn a -> {a, a} end))
        end)

      make_struct_map({mappings, to_t, binding})
    else
      make_struct_map({mappings, to_t, binding})
    end
  end

  defp map_p(from_t, to_t, name, auto?, children) do
    binding = random_id()
    created_map = map_internal(children, to_t, binding, auto?, from_t)
    binding = Macro.var(binding, __MODULE__)

    quote do
      def unquote(name)(unquote(binding) = %unquote(from_t){}) do
        unquote(created_map)
      end

      def unquote(:"#{name}_map")(unquote(binding) = %unquote(from_t){}) do
        Map.from_struct(unquote(created_map))
      end
    end
  end

  @spec map(module(), module(), atom, [], do: any()) :: any()
  defmacro map(from_t, to_t, name, opts \\ [], do: block) do
    children = get_children(block)
    from_t = Macro.expand(from_t, __CALLER__)
    to_t = Macro.expand(to_t, __CALLER__)
    auto? = Keyword.get(opts, :auto, false)
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
    to_t = Macro.expand(to_t, __CALLER__)
    nest_scope = fn binding -> map_internal(children, to_t, binding, false) end
    {:nest, {dest_key, nest_scope}}
  end

  @spec drop(atom()) :: any()
  defmacro drop(src_key) do
    {:drop, {src_key}}
  end
end
