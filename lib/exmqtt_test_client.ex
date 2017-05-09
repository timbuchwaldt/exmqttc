defmodule Exmqtt.Testclient do
  @moduledoc false

  def init do
    {:ok, []}
  end

  def connected(state) do
    send(:testclient, :connected)
    {:ok, state}
  end

  def disconnected(state) do
    send(:testclient, :disconnected)
    {:ok, state}
  end

  def publish(topic, payload, state) do
    send(:testclient, {:publish, topic, payload})
    {:ok, state}
  end
end
