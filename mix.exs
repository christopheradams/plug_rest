defmodule PlugRest.Mixfile do
  use Mix.Project

  @project_description """
  REST behaviour and Plug router for hypermedia web applications
  """

  @version "0.12.0"
  @source_url "https://github.com/christopheradams/plug_rest"

  def project do
    [app: :plug_rest,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     dialyzer: [plt_add_apps: [:mix, :eex]],
     docs: docs(),
     description: @project_description,
     source_url: @source_url,
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:plug, :cowboy, :logger, :inets, :public_key]]
  end

  defp deps do
    [{:plug, "~> 1.3"},
     {:cowboy, "~> 1.0"},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:dialyxir, "~> 0.4", only: [:dev]}]
  end

  defp docs() do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md": [title: "README"]
      ]
    ]
  end

  defp package do
    [
     name: :plug_rest,
     maintainers: ["Christopher Adams"],
     licenses: ["Apache 2.0"],
     links: %{
       "GitHub" => @source_url
     }
    ]
  end
end
