defmodule PlugRest.Mixfile do
  use Mix.Project

  @version "0.4.1"

  def project do
    [app: :plug_rest,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_deps: true],
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:plug, "~> 1.0"},
     {:cowboy, "~> 1.0"},
     {:dialyxir, "~> 0.3.5", only: [:dev]}]

  end

  defp description do
    """
    An Elixir port of Cowboy's REST behaviour for Plug applications
    """
  end

  defp package do
    [
     name: :plug_rest,
     maintainers: ["Christopher Adams"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/christopheradams/plug_rest"}
    ]
  end


end
