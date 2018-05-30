defmodule AwsExRay.Store.ProcessMonitor do

  use GenServer

  alias AwsExRay.Store.Table

  def start_monitoring(monitor, pid) do
    GenServer.call(monitor, {:monitor, pid})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    {:ok, []}
  end

  def handle_call({:monitor, pid}, _from, state) do
    Process.monitor(pid)
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Table.delete(pid)
    {:noreply, state}
  end

end
