defmodule AwsExRay.Store.MonitorSupervisor do

  @moduledoc ~S"""
  This module supervise monitor servers with poolboy.
  You con configure the number of pool-size. See also AwsExRay.Config.
  """

  use Supervisor

  alias AwsExRay.Config
  alias AwsExRay.Store.ProcessMonitor

  @pool_name :aws_ex_store_pool

  @spec start_monitoring(pid :: pid) :: :ok
  def start_monitoring(pid) do
    :poolboy.transaction(@pool_name, fn monitor ->
      ProcessMonitor.start_monitoring(monitor, pid)
    end)
    :ok
  end

  @spec start_link(any) :: Supervisor.on_start
  def start_link(_args), do: start_link()

  @spec start_link() :: Supervisor.on_start
  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [:poolboy.child_spec(
      @pool_name,
      pool_options(),
      []
    )]
    Supervisor.init(children, strategy: :one_for_one)
  end

  defp pool_options() do
    [
      {:name, {:local, @pool_name}},
      {:worker_module, ProcessMonitor},
      {:size, Config.store_monitor_pool_size},
      {:max_overflow, 0}
    ]
  end

end
