# Exmqttc [![Deps Status](https://beta.hexfaktor.org/badge/all/github/timbuchwaldt/exmqttc.svg)](https://beta.hexfaktor.org/github/timbuchwaldt/exmqttc) [![Build Status](https://travis-ci.org/timbuchwaldt/exmqttc.svg?branch=master)](https://travis-ci.org/timbuchwaldt/exmqttc) [![Inline docs](http://inch-ci.org/github/timbuchwaldt/exmqttc.svg?branch=master)](http://inch-ci.org/github/timbuchwaldt/exmqttc)

Elixir wrapper for the emqttc library.

emqttc must currently be installed manually as it is not available on hex (yet).
## Installation

The package can be installed by adding `exmqttc` and `emqttc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exmqttc, "~> 0.3.0"}, {:emqttc, github: "emqtt/emqttc"}]
end
```


# Usage

Create a callback module:
```elixir
defmodule MyClient do
  require Logger

  def init do
    {:ok, []}
  end

  def handle_connect(state) do
    Logger.debug "Connected"
    {:ok, state}
  end

  def handle_disconnect(state) do
    Logger.debug "Disconnected"
    {:ok, state}
  end

  def handle_publish(topic, payload, state) do
    Logger.debug "Message received on topic #{topic} with payload #{payload}"
    {:ok, state}
  end
end
```

You can keep your own state and return it just like with `:gen_server`.

Start the MQTT connection process by calling `start_link/3`:
```elixir
{:ok, pid} = Exmqttc.start_link(MyClient, [], host: '127.0.0.1')
```


Further docs can be found at [https://hexdocs.pm/exmqttc](https://hexdocs.pm/exmqttc).
