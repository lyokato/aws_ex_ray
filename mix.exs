defmodule AwsExRay.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_ex_ray,
      version: "0.1.8",
      elixir: "~> 1.6",
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      applications: [:logger, :poolboy],
      mod: {AwsExRay.Application, []}
    ]
  end

  defp deps do
    [
      {:mox, "~> 0.3.2", only: :test},
      {:credo, "~> 0.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.15", only: :dev, runtime: false},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:struct_assert, "~> 0.5.2", only: :test},
      {:secure_random, "~> 0.5"}
    ]
  end

  defp package() do
    [
      description: "AWS X-Ray reporter",
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/lyokato/aws_ex_ray",
        "Docs" => "https://hexdocs.pm/aws_ex_ray/AwsExRay.html"
      },
      maintainers: ["Lyo Kato"]
    ]
  end
end
