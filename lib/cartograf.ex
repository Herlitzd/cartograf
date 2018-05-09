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

        {from_symbols_mapped, to_symbols_mapped} =
          Enum.reduce(already_set, {[], []}, fn curr, {f, t} ->
            {[elem(curr, 0) | f], [elem(curr, 1) | t]}
          end)

        from_symbols_mapped = [:__struct__ | from_symbols_mapped]

        not_mapped =
          Enum.filter(Map.keys(from), fn el ->
            !Enum.member?(from_symbols_mapped, el)
          end)

        cond do
          auto? ->
            # try to auto map remaining fields
            do_auto_map(mapped, from, not_mapped, to_symbols_mapped)

          Enum.any?(not_mapped) ->
            # auto is off, but some fields were missed
            raise Cartograf.MappingException, message: "not mapped: #{inspect(not_mapped)}"

          true ->
            # if we get here, then all the fields were already mapped
            # before even checking for auto?
            mapped
        end
      end
    end
  end

  @doc false
  def do_auto_map(mapped_result, from_struct, not_mapped, already_set) do
    Enum.reduce(not_mapped, mapped_result, fn curr, acc ->
      # Try to automap, but don't override explicit binding
      if(Map.has_key?(acc, curr) && !Enum.member?(already_set, curr)) do
        Map.put(acc, curr, Map.get(from_struct, curr))
      else
        raise Cartograf.MappingException, message: "not mapped: #{curr}"
      end
    end)
  end

  @doc false
  def do_explicit_field_translation(from_struct, to_struct, field_fns) do
    Enum.reduce(field_fns, {[], to_struct}, fn fields, {keys, fns} ->
      case fields.(from_struct, fns) do
        {source_dest_tup, mapped_so_far} when is_tuple(source_dest_tup) ->
          {[source_dest_tup | keys], mapped_so_far}

        {source_dest_tup_lst, mapped_so_far} when is_list(source_dest_tup_lst) ->
          {source_dest_tup_lst ++ keys, mapped_so_far}
      end
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

  defmacro const(dest_key, value) do
    quote do
      fn from, to ->
        key = unquote(dest_key)
        {{nil, key}, Map.put(to, key, unquote(value))}
      end
    end
  end

  defmacro nest(to_t, dest_key, do: block) do
    quote do
      fn from, to ->
        {fields, nested} = do_explicit_field_translation(from, %unquote(to_t){}, unquote(block))

        # When working with nested fields, it makes no sense
        # to report which dest fields were mapped as dest is
        # ambigous
        source_fields = Enum.map(fields, fn el -> {elem(el, 0), nil} end)

        {source_fields,
         Map.put(
           to,
           unquote(dest_key),
           nested
         )}
      end
    end
  end
end
