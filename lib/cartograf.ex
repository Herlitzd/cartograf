defmodule Cartograf do
  require IEx

  defmacro __using__(_) do
    quote do
      import Cartograf
      Module.register_attribute(__MODULE__, :already_set, accumulate: true)
    end
  end

  defmacro map(from_t, to_t, name, opts \\ [], do: block) do
    quote do
      def unquote(:"#{name}")(from = %unquote(from_t){}) do
        opts = unquote(opts)
        auto? = Keyword.get(opts, :auto, true)

        {already_set, mapped} =
          do_explicit_field_translation(from, %unquote(to_t){}, unquote(block))

        from_symbols_mapped = Enum.map(already_set, &elem(&1, 0))
        from_symbols_mapped = [:__struct__ | from_symbols_mapped]

        if(auto?) do
          do_auto_map(mapped, from, from_symbols_mapped)
        else
          mapped
        end
      end
    end
  end

  def do_auto_map(mapped_result, from_struct, set_src_keys) do
    not_mapped = Enum.filter(Map.keys(from_struct), fn el -> !Enum.member?(set_src_keys, el) end)
    Enum.reduce(not_mapped, mapped_result, fn curr, acc ->
      if(Map.has_key?(acc, curr)) do
        Map.put(acc, curr, Map.get(from_struct, curr))
      else
        raise Cartograf.MappingException, message: "not mapped: #{curr}"
      end
    end)
  end

  def do_explicit_field_translation(from_struct, to_struct, field_fns) do
      Enum.reduce(field_fns, {[], to_struct}, fn fields, {keys, fns} ->
        {source_dest_tup, mapped_so_far} = fields.(from_struct, fns)
        {[source_dest_tup | keys], mapped_so_far}
      end)
  end

  defmacro let(source_key, dest_key) do
    quote do
      fn from, to ->
        {{unquote(source_key), unquote(dest_key)},
         Map.put(to, unquote(dest_key), Map.get(from, unquote(source_key)))}
      end
    end
  end
  defmacro drop(source_key) do
    quote do
      fn from, to ->
        {{unquote(source_key), nil}, to}
      end
    end
  end
end
