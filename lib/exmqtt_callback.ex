defmodule Exmqttc.Callback do
  use GenServer
  @callback init() :: {:ok, any()}
  @callback connected(any) :: {:ok, any()}
  @callback disconnected(any) :: {:ok, any()}
  @callback publish(string, string, any) :: {:ok, any()}

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
  def handle_cast(:connected, %{cb: cb, state: state}) do
    {:ok, new_state} = cb.connected(state)
    {:noreply, %{cb: cb, state: new_state}}
  end

  @doc false
  def handle_cast(:disconnected, %{cb: cb, state: state}) do
    {:ok, new_state} = cb.disconnected(state)
    {:noreply, %{cb: cb, state: new_state}}
  end

  @doc false
  def handle_cast({:publish, topic, message}, %{cb: cb, state: state}) do
    {:ok, new_state} = cb.publish(topic, message, state)
    {:noreply, %{cb: cb, state: new_state}}
  end
end
