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
  Start the Exmqttc client. `opts` are passed directly to GenServer.
  `mqtt_opts` are reformatted so all options can be passed in as a Keyworld list.
  """
  def start_link(callback_module, opts \\ [], mqtt_opts \\ []) do
    # default client_id to new uuidv4
    GenServer.start_link(__MODULE__, [callback_module, mqtt_opts], opts)
  end

  @doc """
  Subscribe to a topic or a list of topics with a given QoS.
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
  Publish a message to MQTT
  """
  @spec publish(pid, binary, binary, list) :: :ok
  def publish(pid, topic, payload, opts \\ []) do
    GenServer.call(pid, {:publish_message, topic, payload, opts})
  end

  @doc """
  Publish a message to MQTT synchronously
  """
  @spec sync_publish(pid, binary, binary, list) :: :ok
  def sync_publish(pid, topic, payload, opts \\ []) do
    GenServer.call(pid, {:sync_publish_message, topic, payload, opts})
  end


  # GenServer callbacks
  def init([callback_module, opts]) do
    # start callback handler
    {:ok, callback_pid} = Exmqttc.Callback.start_link(callback_module)

    {:ok, mqtt_pid} = opts
    |> Keyword.put_new_lazy(:client_id, fn() -> UUID.uuid4() end)
    |> map_options
    |> :emqttc.start_link
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

  def handle_call({:publish_message, topic, payload, opts}, _from, {mqtt_pid, callback_pid}) do
    :emqttc.publish(mqtt_pid, topic, payload, opts)
    {:reply, :ok, {mqtt_pid, callback_pid}}
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

  # helpers

  defp map_options(input) do
    merged_defaults = Keyword.merge([logger: :error], input)
    Enum.map(merged_defaults, fn({key, value}) ->
      if value == true do
        key
      else
        {key, value}
      end
    end)
  end

end
