defmodule Exmqttc.Callback do
  require Logger
  @moduledoc """
  Behaviour module for Exmqttc callbacks
  """
  use GenServer

  @doc """
  Initializing the callback module, returned data is passed in as state on the next call.
  """
  @callback init() :: {:ok, state :: any()}

  @doc """
  Called once a connection has been established.
  """
  @callback handle_connect(state :: any()) :: {:ok, state :: any()}

  @doc """
  Called on disconnection from the broker.
  """
  @callback handle_disconnect(state :: any()) :: {:ok, state :: any()}

  @doc """
  Called upon reception of a MQTT message, passes in topic and message.
  """
  @callback handle_publish(topic :: String.t(), message :: String.t(), state :: any()) :: {:ok, state :: any()}

  @doc """
  Called if the connection process or the callback handler process receive unknown `handle_call/3` calls.
  """
  @callback handle_call(message :: term(), from :: {pid(), atom()}, state :: term()) :: {:ok, state :: term()}

  @doc """
  Called if the connection process or the callback handler process receive unknown `handle_cast/2` calls.
  """
  @callback handle_cast(message :: term(), state :: term()) :: {:ok, state :: term()} :: {:ok, state :: term()}

  @doc """
  Called if the connection process or the callback handler process receive unknown `handle_info/2` calls, and by extend also unknown Elixir messages.
  """
  @callback handle_info(message :: term(), state :: term()) :: {:ok, state :: term()} :: {:ok, state :: term()}

  @doc false
  defmacro __using__(_opts) do
  quote location: :keep do
    @behaviour Exmqttc.Callback
    def init do
      {:ok, []}
    end
    def handle_call(:test, _from, state) do
      {:ok, state}
    end

    def handle_cast(:test, state) do
      {:ok, state}
    end

    def handle_info(:test, state) do
      {:ok, state}
    end
    defoverridable [init: 0, handle_call: 3, handle_info: 2, handle_cast: 2]
  end
  end

  @doc false
  def start_link(module) do
    GenServer.start_link(__MODULE__, {module, self()})
  end

  @doc false
  def init({cb, connection_pid}) do
    {:ok, state} = cb.init()
    {:ok, %{cb: cb, state: state, connection_pid: connection_pid}}
  end

  @doc false
  def handle_cast(:connect, %{cb: cb, state: state, connection_pid: connection_pid}) do
    {:ok, new_state} = cb.handle_connect(state)
    {:noreply, %{cb: cb, state: new_state, connection_pid: connection_pid}}
  end

  @doc false
  def handle_cast(:disconnect, %{cb: cb, state: state, connection_pid: connection_pid}) do
    {:ok, new_state} = cb.handle_disconnect(state)
    {:noreply, %{cb: cb, state: new_state, connection_pid: connection_pid}}
  end

  @doc false
  def handle_cast({:publish, topic, message}, %{cb: cb, state: state, connection_pid: connection_pid}) do
    case cb.handle_publish(topic, message, state) do
      {:ok, new_state} ->
        {:noreply, %{cb: cb, state: new_state, connection_pid: connection_pid}}
      {:reply, reply_topic, reply_message, new_state} ->
        Exmqttc.publish(connection_pid, reply_topic, reply_message)
        {:noreply, %{cb: cb, state: new_state, connection_pid: connection_pid}}
    end
  end

  # Pass unknown casts through
  @doc false
  def handle_cast(message, %{cb: cb, state: state, connection_pid: connection_pid}) do
    {:ok, new_state} = cb.handle_cast(message, state)
    {:noreply, %{cb: cb, state: new_state, connection_pid: connection_pid}}
  end

  # Pass unknown calls through
  @doc false
  def handle_call(message, from, %{cb: cb, state: state, connection_pid: connection_pid}) do
    {:ok, new_state} = cb.handle_call(message, from, state)
    {:reply, :ok,  %{cb: cb, state: new_state, connection_pid: connection_pid}}
  end

  # Pass unknown infos through
  @doc false
  def handle_info(message, %{cb: cb, state: state, connection_pid: connection_pid}) do
    {:ok, new_state} = cb.handle_info(message, state)
    {:noreply, %{cb: cb, state: new_state, connection_pid: connection_pid}}
  end
end
