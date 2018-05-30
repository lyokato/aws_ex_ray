defmodule AwsExRay.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_ex_ray,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      applications: [:logger, :poolboy, :plug, :httpoison],
      mod: {AwsExRay.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.1"},
      {:mox, "~> 0.3.2", only: :test},
      {:plug, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:secure_random, "~> 0.5"}
    ]
  end
end
