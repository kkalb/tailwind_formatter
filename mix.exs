defmodule TailwindFormatter.MixProject do
  use Mix.Project

  @version "0.3.1"
  @url "https://github.com/100phlecs/tailwind_formatter"

  def project do
    [
      app: :tailwind_formatter,
      version: @version,
      elixir: "~> 1.13",
      name: "TailwindFormatter",
      description: "A Mix formatter that sorts your Tailwind classes",
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: dialyzer()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp docs do
    [main: "TailwindFormatter", source_ref: "v#{@version}", source_url: @url]
  end

  defp package do
    %{licenses: ["MIT"], maintainers: ["100phlecs"], links: %{"GitHub" => @url}}
  end

  defp dialyzer() do
    [plt_add_apps: [:mix]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:credo, "~> 1.6.7", [only: [:dev, :test], runtime: false]},
      {:dialyxir, "~> 1.2", [only: [:dev, :test], runtime: false]},
      {:recode, "~> 0.4", only: [:test, :dev]},
      {:phoenix_live_view, ">= 0.17.6", optional: true}
    ]
  end
end
