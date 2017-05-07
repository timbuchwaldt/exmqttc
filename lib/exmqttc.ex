defmodule Exmqttc do
  use GenServer
  @moduledoc """
  Documentation for Exmqttc.
  """

  # API

  def start_link(callback_module, opts\\[], mqtt_opts\\[logger: :error]) do
    # default client_id to new uuidv4
    GenServer.start_link(__MODULE__, [callback_module, mqtt_opts], opts)
  end

  def subscribe(pid, topics, qos\\:qos0) do
    GenServer.call(pid, {:subscribe_topics, topics, qos})
  end

  def sync_subscribe(pid, topics) do
    GenServer.call(pid, {:sync_subscribe_topics, topics})
  end

  def publish(pid, topic, payload, opts\\[]) do
    GenServer.call(pid, {:publish_message, topic, payload, opts})
  end

  def sync_publish(pid, topic, payload, opts\\[]) do
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
    GenServer.cast(callback_pid, :connected)
    {:noreply, {mqtt_pid, callback_pid}}
  end

  def handle_info({:mqttc, _pid, :disconnected}, {mqtt_pid, callback_pid}) do
    GenServer.cast(callback_pid, :disconnected)
    {:noreply, {mqtt_pid, callback_pid}}
  end

  def handle_info({:publish, topic, message}, {mqtt_pid, callback_pid}) do
    GenServer.cast(callback_pid, {:publish, topic, message})
    {:noreply, {mqtt_pid, callback_pid}}
  end

  # helpers

  defp map_options(input) do
    Enum.map(input, fn({key, value})->
      if value == true do
        key
      else
        {key, value}
      end
    end)
  end

end
