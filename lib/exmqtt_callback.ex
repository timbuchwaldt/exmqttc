defmodule Exmqttc.Callback do
  @moduledoc false
  use GenServer

  def start_link(module) do
    GenServer.start_link(__MODULE__, module)
  end

  def init(callback_module) do
    {:ok, callback_module}
  end

  def handle_cast(:connected, callback_module) do
    callback_module.connected()
    {:noreply, callback_module}
  end

  def handle_cast(:disconnected, callback_module) do
    callback_module.disconnected()
    {:noreply, callback_module}
  end

  def handle_cast({:publish, topic, message}, callback_module) do
    callback_module.publish(topic, message)
    {:noreply, callback_module}
  end
end
