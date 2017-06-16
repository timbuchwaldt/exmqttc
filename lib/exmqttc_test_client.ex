defmodule Exmqttc.Testclient do
  @moduledoc false
  use Exmqttc.Callback

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

  def handle_call(:test, _from, state) do
    send(:testclient, :test_call)
    {:ok, state}
  end

  def handle_cast(:test, state) do
    send(:testclient, :test_cast)
    {:ok, state}
  end

  def handle_info(:test, state) do
    send(:testclient, :test_info)
    {:ok, state}
  end
end
