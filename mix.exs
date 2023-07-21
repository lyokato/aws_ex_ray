defmodule AwsExRay.MixProject do
  use Mix.Project

  def project do
    [
      app: :aws_ex_ray,
      version: "0.1.16",
      elixir: "~> 1.14",
      package: package(),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_deps: :transitive,
      ],
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger, :poolboy],
      mod: {AwsExRay.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.1"},
      {:hackney, "~> 1.9"},
      {:mox, "~> 0.3.2", only: :test},
      {:credo, "~> 0.3", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:struct_assert, "~> 0.5.2", only: :test},
      {:dialyxir, "~> 1.3", only: [:dev], runtime: false},
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
