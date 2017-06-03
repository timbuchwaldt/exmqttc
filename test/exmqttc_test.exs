defmodule ExmqttcTest do
  use ExUnit.Case, async: false
  doctest Exmqttc

  setup do
    Process.register(self(), :testclient)
    :ok
  end

  test "connecting with minimal options" do
    {:ok, pid} = Exmqttc.start_link(Exmqtt.Testclient, [], host: '127.0.0.1')
    assert_receive :connected
    Exmqttc.disconnect(pid)
  end

  test "connecting with registered names" do
    {:ok, pid} = Exmqttc.start_link(Exmqtt.Testclient, [name: :my_client], host: '127.0.0.1')
    assert_receive :connected
    Exmqttc.disconnect(pid)
  end

  test "connecting with enhanced options" do
    {:ok, pid} = Exmqttc.start_link(Exmqtt.Testclient, [name: :my_client_2], keepalive: 30, host: '127.0.0.1')
    assert_receive :connected
    Exmqttc.disconnect(pid)
  end

  test "subscribing and sending" do
    {:ok, pid} = Exmqttc.start_link(Exmqtt.Testclient, [name: :my_client_3], keepalive: 30, host: '127.0.0.1')
    assert_receive :connected

    Exmqttc.subscribe(:my_client_3, "test")
    Exmqttc.publish(:my_client_3, "test", "foo")
    assert_receive {:publish, "test", "foo"}
    Exmqttc.disconnect(pid)
  end

  test "synchronous subscribing and sending" do
    {:ok, pid} = Exmqttc.start_link(Exmqtt.Testclient, [name: :my_client_4], keepalive: 30, host: '127.0.0.1')
    assert_receive :connected

    Exmqttc.sync_subscribe(:my_client_4, "test2")
    Exmqttc.sync_publish(:my_client_4, "test2", "foo")
    assert_receive {:publish, "test2", "foo"}
    Exmqttc.disconnect(pid)
  end

end
