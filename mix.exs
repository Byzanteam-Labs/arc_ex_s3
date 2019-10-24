defmodule ArcExS3.MixProject do
  use Mix.Project

  @project_host "https://github.com/GreenNerd-Labs/arc_ex_s3"
  @version "0.0.3"

  def project do
    [
      app: :arc_ex_s3,
      version: @version,
      source_url: @project_host,
      homepage_url: @project_host,
      description: description(),
      package: package(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:ex_arc, github: "Byzanteam-Labs/ex_arc", branch: "develop"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:httpoison, "~> 1.2.0", override: true}
    ]
  end

  defp description do
    "Extended S3 storage provider for Arc"
  end

  defp package do
    [
      name: :arc_ex_s3,
      files: ["lib", "mix.exs", "README.md", "MIT-LICENSE"],
      maintainers: ["CptBreeza"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_host}
    ]
  end
end
