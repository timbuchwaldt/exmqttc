defmodule Exmqttc.Testclient do
  @moduledoc false

  def init do
    {:ok, []}
  end

  def handle_connect(state) do
    send(:testclient, :connected)
    {:ok, state}
  end

  def handle_disconnect(state) do
    send(:testclient, :disconnected)
    {:ok, state}
  end

  def handle_publish("reply_topic", payload, state) do
    send(:testclient, {:publish, "reply_topic", payload})
    {:reply, "foobar", "testmessage",  state}
  end

  def handle_publish(topic, payload, state) do
    send(:testclient, {:publish, topic, payload})
    {:ok, state}
  end
end
