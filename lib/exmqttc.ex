defmodule Exmqttc do
  use GenServer

  @moduledoc """
  `Exmqttc` provides a connection to a MQTT server based on [emqttc](https://github.com/emqtt/emqttc)
  """

  @typedoc """
  A PID like type
  """
  @type pidlike :: pid() | port() | atom() | {atom(), node()}

  @typedoc """
  A QoS level
  """
  @type qos :: :qos0 | :qos1 | :qos2

  @typedoc """
  A single topic, a list of topics or a list of tuples of topic and QoS level
  """
  @type topics :: String.t() | [String.t()] | [{String.t(), qos}]

  # API

  @doc """
  Start the Exmqttc client. `callback_module` is used for callbacks and should implement the `Exmqttc.Callback` behaviour.
   `opts` are passed directly to GenServer.
  `mqtt_opts` are reformatted so all options can be passed in as a Keyworld list.
  Params are passed to your callbacks init function.

  `mqtt_opts` supports the following options:
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

  """
  def start_link(callback_module, opts \\ [], mqtt_opts \\ [], params \\ []) do
    # default client_id to new uuidv4
    GenServer.start_link(__MODULE__, [callback_module, mqtt_opts, params], opts)
  end

  @doc """
  Subscribe to the given topic(s) given as `topics` with a given `qos`.
  """
  @spec subscribe(pidlike, topics, qos) :: :ok
  def subscribe(pid, topics, qos \\ :qos0) do
    GenServer.call(pid, {:subscribe_topics, topics, qos})
  end

  @doc """
  Subscribe to the given topics while blocking until the subscribtion has been confirmed by the server.
  """
  @spec sync_subscribe(pid, topics) :: :ok
  def sync_subscribe(pid, topics) do
    GenServer.call(pid, {:sync_subscribe_topics, topics})
  end

  @doc """
  Unsubscribe from the given topic(s) given as `topics`.
  """
  @spec unsubscribe(pidlike, topics) :: :ok
  def unsubscribe(pid, topics) do
    GenServer.call(pid, {:unsubscribe_topics, topics})
  end

  @doc """
  Publish a message to MQTT.
  `opts` is a keywordlist and supports `:retain` with a boolean and `:qos` with an integer from 1 to 3
  """
  @spec publish(pid, binary, binary, list) :: :ok
  def publish(pid, topic, payload, opts \\ []) do
    GenServer.call(pid, {:publish_message, topic, payload, opts})
  end

  @doc """
  Publish a message to MQTT synchronously.
  `opts` is a keywordlist and supports `:retain` with a boolean and `:qos` with an integer from 1 to 3
  """
  @spec sync_publish(pid, binary, binary, list) :: :ok
  def sync_publish(pid, topic, payload, opts \\ []) do
    GenServer.call(pid, {:sync_publish_message, topic, payload, opts})
  end

  @doc """
  Disconnect socket from MQTT server
  """
  @spec disconnect(pid) :: :ok
  def disconnect(pid) do
    GenServer.call(pid, :disconnect)
  end

  # GenServer callbacks
  def init([callback_module, opts, params]) do
    # start callback handler
    {:ok, callback_pid} = Exmqttc.Callback.start_link(callback_module, params)

    {:ok, mqtt_pid} =
      opts
      |> Keyword.put_new_lazy(:client_id, fn -> UUID.uuid4() end)
      |> map_options
      |> :emqttc.start_link()

    {:ok, {mqtt_pid, callback_pid}}
  end

  def handle_call({:sync_subscribe_topics, topics}, _from, {mqtt_pid, callback_pid}) do
    res = :emqttc.sync_subscribe(mqtt_pid, topics)
    {:reply, res, {mqtt_pid, callback_pid}}
  end

  def handle_call({:sync_publish_message, topic, payload, opts}, _from, {mqtt_pid, callback_pid}) do
    res = :emqttc.sync_publish(mqtt_pid, topic, payload, opts)
    {:reply, res, {mqtt_pid, callback_pid}}
  end

  def handle_call({:subscribe_topics, topics, qos}, _from, {mqtt_pid, callback_pid}) do
    :ok = :emqttc.subscribe(mqtt_pid, topics, qos)
    {:reply, :ok, {mqtt_pid, callback_pid}}
  end

  def handle_call({:unsubscribe_topics, topics}, _from, {mqtt_pid, callback_pid}) do
    :ok = :emqttc.unsubscribe(mqtt_pid, topics)
    {:reply, :ok, {mqtt_pid, callback_pid}}
  end

  def handle_call({:publish_message, topic, payload, opts}, _from, {mqtt_pid, callback_pid}) do
    :emqttc.publish(mqtt_pid, topic, payload, opts)
    {:reply, :ok, {mqtt_pid, callback_pid}}
  end

  def handle_call(:disconnect, _from, {mqtt_pid, callback_pid}) do
    :emqttc.disconnect(mqtt_pid)
    {:reply, :ok, {mqtt_pid, callback_pid}}
  end

  def handle_call(message, _from, state = {_mqtt_pid, callback_pid}) do
    reply = GenServer.call(callback_pid, message)
    {:reply, reply, state}
  end

  def handle_cast(message, state = {_mqtt_pid, callback_pid}) do
    GenServer.cast(callback_pid, message)
    {:noreply, state}
  end

  # emqttc messages

  def handle_info({:mqttc, _pid, :connected}, {mqtt_pid, callback_pid}) do
    GenServer.cast(callback_pid, :connect)
    {:noreply, {mqtt_pid, callback_pid}}
  end

  def handle_info({:mqttc, _pid, :disconnected}, {mqtt_pid, callback_pid}) do
    GenServer.cast(callback_pid, :disconnect)
    {:noreply, {mqtt_pid, callback_pid}}
  end

  def handle_info({:publish, topic, message}, {mqtt_pid, callback_pid}) do
    GenServer.cast(callback_pid, {:publish, topic, message})
    {:noreply, {mqtt_pid, callback_pid}}
  end

  def handle_info(message, state = {_mqtt_pid, callback_pid}) do
    send(callback_pid, message)
    {:noreply, state}
  end

  # helpers

  defp map_options(input) do
    merged_defaults = Keyword.merge([logger: :error], input)

    Enum.map(merged_defaults, fn {key, value} ->
      if value == true do
        key
      else
        {key, value}
      end
    end)
  end
end
