defmodule Exmqttc.Mixfile do
  use Mix.Project

  def project do
    [app: :exmqttc,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  def package do
    %{
      name: :exmqttc,
      files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
      maintainers: ["Tim Buchwaldt"],
      description: "Elixir wrapper for the [emqttc](https://github.com/emqtt/emqttc) library.",
      licenses: ["MIT"],
    }
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:emqttc, github: "emqtt/emqttc"},
      {:uuid, "~> 1.1"}
    ]
  end
end
