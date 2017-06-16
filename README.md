# Exmqttc [![Deps Status](https://beta.hexfaktor.org/badge/all/github/timbuchwaldt/exmqttc.svg)](https://beta.hexfaktor.org/github/timbuchwaldt/exmqttc) [![Build Status](https://travis-ci.org/timbuchwaldt/exmqttc.svg?branch=master)](https://travis-ci.org/timbuchwaldt/exmqttc) [![Inline docs](http://inch-ci.org/github/timbuchwaldt/exmqttc.svg?branch=master)](http://inch-ci.org/github/timbuchwaldt/exmqttc)

Elixir wrapper for the emqttc library.

emqttc must currently be installed manually as it is not available on hex (yet).

## Installation

The package can be installed by adding `exmqttc` and `emqttc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exmqttc, "~> 0.3"}, {:emqttc, github: "emqtt/emqttc"}]
end
```


## Usage

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
The last argument to `start_link` is a  keyword list and supports the following options:

- `host`: Connection host, charlist, default: `'localhost'`
- `port`: Connection port, integer, default 1883
- `client_id`: Binary ID for client, automatically set to UUID if not specified
- `clean_sess`: MQTT cleanSession flag. `true` disables persistent sessions on the server
- `keepalive`: Keepalive timer, integer
- `username`: Login username, binary
- `password`: Login password, binary
- `will`: Last will, keywordlist, sample: `[qos: 1, retain: false, topic: "WillTopic", payload: "I died"]`
- `connack_timeout`: Timeout for connack package, integer, default 60
- `puback_timeout`: Timeout for puback package, integer, default 8
- `suback_timeout`: Timeout for suback package, integer, default 4
- `ssl`: List of ssl options
- `auto_resub`: Automatically resubscribe to topics, boolean, default: `false`
- `reconnect`: Automatically reconnect on lost connection, integer (),  default `false`

You can publish messages to the given PID:

```elixir
Exmqttc.publish(pid, "test", "foo")
```

`publish/4` also supports passing in QOS and retain options:
```elixir
Exmqttc.publish(pid, "test", "foo", qos: 2, retain: true)
```

Further docs can be found at [https://hexdocs.pm/exmqttc](https://hexdocs.pm/exmqttc).
