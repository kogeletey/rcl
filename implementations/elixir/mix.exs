defmodule Rcl.MixProject do
  use Mix.Project

  def project do
    [
      app: :rcl,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Native Elixir implementation of RCL v1"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps, do: []

  defp package do
    [
      files: ["lib", "mix.exs", ".formatter.exs", "README.md"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/kogeletey/rcl"}
    ]
  end
end
