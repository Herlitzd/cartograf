defmodule Cartograf do
  require IEx

  @moduledoc """
  Cartograf is a set of elixir macros for mapping fields from
  one struct to another.
  The goal is to make these struct-to-struct translations more
  robust and less cumbersome to write and maintian.

  # Basic Form
  The basic form for using this module is of the form:
  ```elixir
  map Proj.A, Proj.B, :one_to_one do
    [
      let(:a, :aa),
      let(:b, :bb),
      let(:c, :cc),
      let(:d, :dd)
    ]
  end
  ```
  This structure would create a function called `one_to_one/1`
  within whatever module this the macro was invoked within.
  The `one_to_one/1` function would expect a struct of type `Proj.A`
  and return a struct of type `Proj.B` would be returned.
  The struct returned would have the fields of the input struct, `A`,
  mapped to the fields of the returned struct, `B`, thusly:


  | `A`   |   to   | `B`   |
  | ----- |:------:| ----- |
  | `:a`  | &rarr; | `:aa` |
  | `:b`  | &rarr; | `:bb` |
  | `:c`  | &rarr; | `:cc` |
  | `:d`  | &rarr; | `:dd` |

  # Design Philosophy
  Beyond the basic use, there are a number of options that can
  be used within a `map` block beyond just the basic `let(from, to)`
  form. However, it before introducing them, it is important to
  understand the design philosophy and what this `cartograf` is
  meant to do.

  `cartograf` is supposed to be a tool, not a hazzard.
  The point of this project is to create robust mappings from
  one struct to another. As such, there are a few safeties in
  place to protect the developer.
    * `map()` does require that its input struct is of the
    correct type. The function generated leverages pattern
    matching on the argument to ensure that the struct
    type is the one declared when the map was specified.
    * All input fields must be handled. Each `map()`
    will ensure that each field of the input is mentioned
    in some capacity. If a field should not be included in
    in the output struct, no problem, just include a
    `drop(input_key)`. The main purpose for this is catch
    instances where developers add fields to structs, but fail
    to update the maps.

  """

  defmacro __using__(_) do
    quote do
      import Cartograf
    end
  end

  @doc """
  Creates a function in the the current module for mapping from
  struct to another.

  ```elixir
  defmodule A, do: defstruct [:a, :b, :c]
  defmodule B, do: defstruct [:aa, :bb, :cc]
  defmodule YourModule do
    use Cartograf
    map A, B, :a_to_b do
      [
        let(:a, :aa),
        let(:b, :bb),
        let(:c, :cc)
      ]
    end
  end
  ```
  ```elixir
    iex> YourModule.a_to_b(%A{a: 1, b: "2", c: :d})
    %B{aa: 1, bb: "2", cc: :d}
  ```
  """
  @spec map(module(), module(), atom, [], do: any()) :: any()
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
  @doc """
  Specify where the a field in the input should be mapped to
  in the out.
  """
  @spec let(atom(), atom()) :: any()
  defmacro let(source_key, dest_key) do
    quote do
      fn from, to ->
        {{unquote(source_key), unquote(dest_key)},
         Map.put(to, unquote(dest_key), Map.get(from, unquote(source_key)))}
      end
    end
  end
  @doc """
  Allow for a field from the input to be excluded from
  the output.
  """
  @spec drop(atom()) :: any()
  defmacro drop(source_key) do
    quote do
      fn from, to ->
        {{unquote(source_key), nil}, to}
      end
    end
  end

  @doc """
  Allow for a field in the output to be set to a constant
  value.
  """
  @spec const(atom(), any()) :: any()
  defmacro const(dest_key, value) do
    quote do
      fn from, to ->
        key = unquote(dest_key)
        {{nil, key}, Map.put(to, key, unquote(value))}
      end
    end
  end

  @doc """
  Used to specific a nested map within `map()`
  """
  @spec nest(module(), atom(), do: any()) :: any()
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
