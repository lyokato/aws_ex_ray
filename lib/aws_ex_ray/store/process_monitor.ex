defmodule AwsExRay.Store.ProcessMonitor do

  @moduledoc ~S"""
  This GenServer monitors processes which is on context of xray-tracing.
  When a process dies, automatically delete information related to the process
  from ETS table.
  """

  use GenServer

  alias AwsExRay.Store.Table

  @spec start_monitoring(monitor :: pid, pid :: pid) :: :ok
  def start_monitoring(monitor, pid) do
    GenServer.call(monitor, {:monitor, pid})
    :ok
  end

  @spec start_link(any) :: GenServer.on_start
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(_opts) do
    {:ok, []}
  end

  @impl GenServer
  def handle_call({:monitor, pid}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Table.delete(pid)
    {:noreply, state}
  end

end
