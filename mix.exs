defmodule PlugRest.Mixfile do
  use Mix.Project

  @version "0.10.0-dev"

  def project do
    [app: :plug_rest,
     version: @version,
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_deps: true,
                plt_apps: [:erts, :kernel, :stdlib, :crypto, :public_key, :inets]],
     docs: [extras: ["README.md"]],
     description: description(),
     package: package(),
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:plug, :cowboy, :logger]]
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
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:dialyxir, "~> 0.3.5", only: [:dev]}]

  end

  defp description do
    """
    REST behaviour and Plug router for hypermedia web applications
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
