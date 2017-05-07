defmodule Exmqtt.Testclient do
  @moduledoc false
  
  def connected do
    send(:testclient, :connected)
  end

  def disconnected do
    send(:testclient, :disconnected)
  end

  def publish(topic, payload) do
    send(:testclient, {:publish, topic, payload})
  end
end
