defmodule Exmqttc.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exmqttc,
      version: "0.5.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [main: "readme.html#usage", extras: ["README.md"]]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  def package do
    %{
      name: :exmqttc,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Tim Buchwaldt"],
      description:
        "Elixir wrapper for the emqttc library. Some of the features: Reconnection, offline queueing, gen_* like callback APIs, QoS 0-2.",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/timbuchwaldt/exmqttc"}
    }
  end

  defp deps do
    [
      {:emqttc, github: "emqtt/emqttc", only: [:dev, :test]},
      {:uuid, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:credo, "~> 0.8.0", only: [:dev, :test], runtime: false},
      {:inch_ex, "~> 0.5", only: :dev}
    ]
  end
end
