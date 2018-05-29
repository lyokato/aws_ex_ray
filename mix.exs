defmodule AwsExRay.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_ex_ray,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :poolboy],
      mod: {AwsExRay.Application, []}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.5"},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:secure_random, "~> 0.5"}
    ]
  end
end
