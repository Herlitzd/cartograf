defmodule Cartograf do
  @let :let
  @drop :drop
  @nest :nest
  @const :const
  @moduledoc """
  Cartograf is a set of elixir macros for mapping fields from
  one struct to another.
  The goal is to make these struct-to-struct translations more
  robust and less cumbersome to write and maintian.

  ## Basic Form
  The basic form for using this module is of the form:
  ```elixir
  map Proj.A, Proj.B, :one_to_one do
      let :a, :aa
      let :b, :bb
      let :c, :cc
      let :d, :dd
  end
  ```
  This structure would create a function called `one_to_one/1`
  within whatever module this the macro was invoked within.
  The `one_to_one/1` function would expect a struct of type `Proj.A`
  and return a struct of type `Proj.B` would be returned.

  This Map generates a function that contains a native elixir struct syntax for
  the destination struct. For instance, for the *Basic Example*, the following
  function is generated.
  ```
  def one_to_one(bnd = %Proj.A{}) do
    %Proj.B{aa: bdn.a, bb: bdn.b, cc: bdn.c, dd: bdn.d}
  end
  ```

  # Design Philosophy

  `cartograf` is supposed to be a tool, not a hazzard.
  The point of this project is to create robust mappings from
  one struct to another. As such, there are a few safeties in
  place to protect the developer.
    * `map()` does require that its input struct is of the
    correct type. The function generated leverages pattern
    matching on the argument to ensure that the struct
    type is the one declared when the map was specified.
    * All input fields *should* be handled. Each `map()`
    will report any unmapped fields as a warning at compile
    time. This can also be configured to not report a warning, fail
    compilation, for more info see Config. In order to remove these
    warnings, a `drop(input_key)` should be added to the `map()`
    The main purpose for this is catch
    instances where developers add fields to structs, but fail
    to update the maps.
    * Maps do not automatically map identical keys from one struct
    to another by default. To enable this, the `auto: true` option must
    be set in the `map`'s options.

  # Configuration
  Cartograf by default will warn about any unmapped fields to change this behaviour
  the following configuration changes can be made.
  * `config :cartograf, on_missing_key: :warn`

    Log warning for each unmapped field
  * `config :cartograf, on_missing_key: :ignore`

    Ignore unmapped fields, don't warn or throw
  * `config :cartograf, on_missing_key: :throw`

    Raise an exception on unmapped fields, halting compilation

  """

  defmacro __using__(_) do
    quote do
      import Cartograf
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

  defp make_struct_map(bindings, to, bound_var) do
    bound = Macro.var(bound_var, __MODULE__)

    const_mapping =
      Enum.reduce(get_list(bindings, @const), [], fn {t, v}, acc ->
        [{t, v} | acc]
      end)

    let_mapping =
      Enum.reduce(get_list(bindings, @let), [], fn {f, t}, acc ->
        [{t, quote(do: unquote(bound).unquote(f))} | acc]
      end)

    merged_mapping = let_mapping ++ const_mapping
    {:%, [], [to, {:%{}, [], merged_mapping}]}
  end

  defp verify_mappings(mapped_keys, from_t) do
    if(is_nil(from_t)) do
      []
    else
      from_keys = Map.keys(struct(from_t))

      not_mapped =
        Enum.filter(from_keys, fn key -> not (key in mapped_keys) and key != :__struct__ end)

      not_mapped
    end
  end

  defp expand_child_macros(children, binding) do
    Macro.postwalk(children, {[], []}, fn mappings, {mp, nmp} ->
      mappings = Macro.expand(mappings, __ENV__)
      case mappings do
        {@nest, {key, nest_fn}} ->
          {ast, {m, nm}} = nest_fn.(binding)
          {{@const, {key, ast}}, {m ++ mp, nm ++ nmp}}

        other ->
          {other, {mp, nmp}}
      end
    end)
  end

  defp get_mapped_fields(mappings, additional_mapped) do
    Keyword.keys(get_list(mappings, @let)) ++
      Enum.map(get_list(mappings, @const), &elem(&1, 0)) ++
      Enum.map(get_list(mappings, @drop), &elem(&1, 0)) ++ additional_mapped
  end

  defp auto_map_fields(true, mappings, mapped_nested, to_t, from_t) do
    to_atoms = Map.keys(struct(to_t))
    from_atoms = Map.keys(struct(from_t))
    # Get keys that are already mapped
    mapped = get_mapped_fields(mappings, mapped_nested)

    mapped = Enum.uniq(mapped)
    # Get shared keys between to and from
    shared = Enum.filter(to_atoms, fn key -> key in from_atoms end)

    # Get shared keys that are not mapped
    shared = Enum.filter(shared, fn key -> not (key in mapped) && key != :__struct__ end)
    new_lets = Keyword.new(Enum.map(shared, fn a -> {a, a} end))
    # Add let entries for missing shared keys
    Map.update(mappings, @let, new_lets, fn val ->
      Keyword.merge(val, new_lets)
    end)
  end

  defp auto_map_fields(false, mappings, _, _, _) do
    mappings
  end

  defp create_map(children, to_t, binding, auto?, from_t \\ nil) do
    {children, {mapped_n, _not_mapped_n}} = expand_child_macros(children, binding)
    mappings = tokenize(children)
    mappings = auto_map_fields(auto?, mappings, mapped_n, to_t, from_t)
    mapped = get_mapped_fields(mappings, mapped_n)
    mapped = Enum.uniq(mapped)
    not_mapped = verify_mappings(mapped, from_t)
    {make_struct_map(mappings, to_t, binding), {mapped, not_mapped}}
  end

  defp report_not_mapped(not_mapped, name, env) do
    if(Enum.any?(not_mapped)) do
      msg =
        "In map \"#{name}\" the following source keys are not mapped: \n#{inspect(not_mapped)}"

      stack = Macro.Env.stacktrace(env)

      case Application.get_env(:cartograf, :on_missing_key, :warn) do
        :warn ->
          IO.warn(msg, stack)

        :throw ->
          reraise(Cartograf.MappingException, [message: msg], stack)

        :ignore ->
          nil

        u ->
          IO.warn(
            "Cartograf expected config field :on_missing_key to
            be either :warn, :throw, or :ignore, got :#{u}",
            stack
          )

          IO.warn(msg, stack)
      end
    end
  end

  defp map_p(from_t, to_t, name, auto?, map?, children, env) do
    binding_raw = :carto
    binding = Macro.var(binding_raw, __MODULE__)

    {created_map, {_mapped, not_mapped}} = create_map(children, to_t, binding_raw, auto?, from_t)

    report_not_mapped(not_mapped, name, env)

    main =
      quote do
        def unquote(name)(unquote(binding) = %unquote(from_t){}) do
          unquote(created_map)
        end
      end

    if(map?) do
      map =
        quote do
          def unquote(:"#{name}_map")(unquote(binding) = %unquote(from_t){}) do
            Map.from_struct(unquote(created_map))
          end
        end

      {main, map}
    else
      main
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
        let :a, :aa
        let :b, :bb
        let :c, :cc
    end
  end
  ```
  ```elixir
    iex> YourModule.a_to_b(%A{a: 1, b: "2", c: :d})
    %B{aa: 1, bb: "2", cc: :d}
  ```
  The options:
  * `auto: true` create bindings for all matching keys of the two
   structs which are not already mapped
  * `map: true` create a second anologous method `'name'_map` which will return
   a map instead of the struct (some libraries rely of creating a struct for
  you from a map of fields)
  """
  @spec map(module(), module(), atom, [], do: any()) :: any()
  defmacro map(from_t, to_t, name, opts \\ [], do: block) do
    children = get_children(block)
    from_t = Macro.expand(from_t, __CALLER__)
    to_t = Macro.expand(to_t, __CALLER__)
    auto? = Keyword.get(opts, :auto, false)
    map? = Keyword.get(opts, :map, false)
    map_p(from_t, to_t, name, auto?, map?, children, __CALLER__)
  end

  @doc """
  Specify where the a field in the input should be mapped to
  in the out.
  """
  @spec let(atom(), atom()) :: any()
  defmacro let(source_key, dest_key) do
    {@let, {source_key, dest_key}}
  end

  @doc """
  Allow for a field in the output to be set to a constant
  value.
  """
  @spec const(atom(), any()) :: any()
  defmacro const(dest_key, val) do
    {@const, {dest_key, val}}
  end

  @doc """
  Used to specify a nested map within `map()`.

  This resulting struct will have the type of to_t.
  No options are available for this macro.
  """
  @spec nest(atom(), module(), do: any()) :: any()
  defmacro nest(dest_key, to_t, do: block) do
    children = get_children(block)
    to_t = Macro.expand(to_t, __CALLER__)
    nest_scope = fn binding -> create_map(children, to_t, binding, false) end
    {@nest, {dest_key, nest_scope}}
  end

  @doc """
  Allow for a field from the input to be excluded from
  the output.

  Most useful when using `auto`, however it
  is recommended to use this for any non-mapped.
  """
  @spec drop(atom()) :: any()
  defmacro drop(src_key) do
    {@drop, {src_key}}
  end
end
