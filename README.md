# Exmqttc [![Deps Status](https://beta.hexfaktor.org/badge/all/github/timbuchwaldt/exmqttc.svg)](https://beta.hexfaktor.org/github/timbuchwaldt/exmqttc) [![Build Status](https://travis-ci.org/timbuchwaldt/exmqttc.svg?branch=master)](https://travis-ci.org/timbuchwaldt/exmqttc) [![Inline docs](http://inch-ci.org/github/timbuchwaldt/exmqttc.svg?branch=master)](http://inch-ci.org/github/timbuchwaldt/exmqttc)

Elixir wrapper for the emqttc library.

emqttc must currently be installed manually as it is not available on hex (yet).
## Installation

The package can be installedby adding `exmqttc` and `emqttc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exmqttc, "~> 0.1.0"}, {:emqttc, github: "emqtt/emqttc"}]
end
```

The docs can be found at [https://hexdocs.pm/exmqttc](https://hexdocs.pm/exmqttc).
