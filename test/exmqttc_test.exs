defmodule ExmqttcTest do
  use ExUnit.Case, async: false
  doctest Exmqttc

  setup do
    Process.register(self(), :testclient)
    :ok
  end

  test "connecting with minimal options" do
    {:ok, pid} = Exmqttc.start_link(Exmqttc.Testclient, [], host: '127.0.0.1')
    assert_receive :connected, 250
    Exmqttc.disconnect(pid)
  end

  test "connecting with registered names" do
    {:ok, pid} = Exmqttc.start_link(Exmqttc.Testclient, [name: :my_client], host: '127.0.0.1')
    assert_receive :connected, 250
    Exmqttc.disconnect(pid)
  end

  test "connecting with enhanced options" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_2],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250
    Exmqttc.disconnect(pid)
  end

  test "subscribing and sending" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_3],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250

    Exmqttc.subscribe(:my_client_3, "test")
    Exmqttc.publish(:my_client_3, "test", "foo")
    assert_receive {:publish, "test", "foo"}, 250
    Exmqttc.disconnect(pid)
  end

  test "synchronous subscribing and sending" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_4],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250

    Exmqttc.sync_subscribe(:my_client_4, "test2")
    Exmqttc.sync_publish(:my_client_4, "test2", "foo")
    assert_receive {:publish, "test2", "foo"}, 250
    Exmqttc.disconnect(pid)
  end

  test "replying in the callback module" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_6],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250

    Exmqttc.subscribe(:my_client_6, "reply_topic")
    Exmqttc.subscribe(:my_client_6, "foobar")
    Exmqttc.publish(:my_client_6, "reply_topic", "foo")
    assert_receive {:publish, "reply_topic", "foo"}, 250
    assert_receive {:publish, "foobar", "testmessage"}, 250
    Exmqttc.disconnect(pid)
  end

  test "passing through messages" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_7],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250
    send(:my_client_7, :test)
    assert_receive :test_info, 250
    Exmqttc.disconnect(pid)
  end

  test "passing through calls" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_8],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250
    GenServer.call(:my_client_8, :test)
    assert_receive :test_call, 250
    Exmqttc.disconnect(pid)
  end

  test "passing through casts" do
    {:ok, pid} =
      Exmqttc.start_link(
        Exmqttc.Testclient,
        [name: :my_client_9],
        keepalive: 30,
        host: '127.0.0.1'
      )

    assert_receive :connected, 250
    GenServer.cast(:my_client_9, :test)
    assert_receive :test_cast, 250
    Exmqttc.disconnect(pid)
  end
end
