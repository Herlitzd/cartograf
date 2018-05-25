defmodule(D.A, do: defstruct([:a, :b, :c]))
defmodule(D.B, do: defstruct([:d, :b, :c]))

defmodule Test do
  import Fancy
  use Cartograf
  import D.A
  import D.B


  fancy do
    shiny(:a, :b)
    shiny(:b, :c)
    shiny(:c, :d)
  end

  map D.A, D.B, :ab do
    [
      let(:a, :b),
      let(:b, :c),
      let(:c, :d)
    ]
  end

  def test() do
    a = a(%{a: "a", b: "b", c: "c"})
    ab = ab(%D.A{a: "a", b: "b", c: "c"})
    {a, ab}
  end

  def disassemble() do
    beam_file = "_build/dev/lib/cartograf/ebin/Elixir.Fancy.beam"
    beam_file = String.to_char_list(beam_file)

    {:ok, {_, [{:abstract_code, {_, ac}}]}} =
      :beam_lib.chunks(
        beam_file,
        [:abstract_code]
      )

    :io.fwrite('~s~n', [:erl_prettypr.format(:erl_syntax.form_list(ac))])
  end
end


"""
defmodule K do
  import Fancy
  import Mex

  mex 3 do
    fancy do
      shiny(:a, :b)
      shiny(:b, :c)
      shiny(:c, :d)
    end
  end
end

defmodule Q do
  import Cartograf
  import Mex

  mex 3 do
    map D.A, D.B, :ab do
      [
        let(:a, :b),
        let(:b, :c),
        let(:c, :d)
      ]
    end
  end
end

"""
