defmodule Exmqttc.Callback do
  @moduledoc """
  Behaviour module for Exmqttc Callbacks
  """
  use GenServer

  @doc """
  Initializing the callback module, returned data is passed in as state on the next call.
  """
  @callback init() :: {:ok, state :: any()}

  @doc """
  Called once a connection has been established.
  """
  @callback handle_connected(state :: any()) :: {:ok, state :: any()}

  @doc """
  Called on disconnection from the broker.
  """
  @callback handle_disconnected(state :: any()) :: {:ok, state :: any()}

  @doc """
  Called upon reception of a MQTT message, passes in topic and message.
  """
  @callback handle_publish(topic :: String.t(), message :: String.t(), state :: any()) :: {:ok, state :: any()}

  @doc false
  def start_link(module) do
    GenServer.start_link(__MODULE__, module, name: :"#{module}.Callback")
  end

  @doc false
  def init(cb) do
    {:ok, state} = cb.init()
    {:ok, %{cb: cb, state: state}}
  end

  @doc false
  def handle_cast(:connect, %{cb: cb, state: state}) do
    {:ok, new_state} = cb.handle_connect(state)
    {:noreply, %{cb: cb, state: new_state}}
  end

  @doc false
  def handle_cast(:disconnect, %{cb: cb, state: state}) do
    {:ok, new_state} = cb.handle_disconnect(state)
    {:noreply, %{cb: cb, state: new_state}}
  end

  @doc false
  def handle_cast({:publish, topic, message}, %{cb: cb, state: state}) do
    {:ok, new_state} = cb.handle_publish(topic, message, state)
    {:noreply, %{cb: cb, state: new_state}}
  end
end
