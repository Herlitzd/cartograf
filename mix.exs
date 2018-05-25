defmodule Cartograf.MixProject do
  use Mix.Project

  def project do
    [
      app: :cartograf,
      version: "0.1.0",
      elixir: "~> 1.6",
      deps: deps(),
      # Hex Config
      description: description(),
      package: package(),

      # Exdoc Config
      name: "Cartograf",
      source_url: "https://github.com/Herlitzd/cartograf",
      # The main page in the docs
      docs: [main: "Cartograf", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:ex_doc, "~> 0.16", only: :dev, runtime: false}, {:mex, "~> 0.0.1", only: :dev}]
  end

  defp description, do: "A set of macros to help facilitate struct-to-struct field mapping."

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "cartograf",
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Devon Herlitz"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Herlitzd/cartograf"}
    ]
  end
end
