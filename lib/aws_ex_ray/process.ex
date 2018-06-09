defmodule AwsExRay.Process do

  @moduledoc ~S"""
  ## Segments in multiple processes

  Following example doesn't work.
  `start_subsegment` returns always `{:error, :out_of_xray}`.
  Because the subsegment is not on the process which start tracing.

  Pay attention when you use Task.Supervisor or GenServer.

  ```elixir
  segment = AwsExRay.start_tracing(trace, "root_segment_name")

  Task.Supervisor.start_child(MyTaskSupervisor, fn ->

    ####################################################################
    # this function is executed on different process as root-segment!!!
    ####################################################################

    current_trace = AwsExRay.start_subsegment("subsegment-name")

    do_some_work()

    case current_trace do
      {:ok, subsegment} ->
        AwsExRay.finish_subsegment(subsegment)

      {:error, :out_of_xray} -> :ok
    end

  end)
  ```
  The solution.

  Call `AwsExRay.Process.keep_tracing(process_which_starts_tracing)` like following

  ```elixir
  segment = AwsExRay.start_tracing(trace, "root_segment_name")

  tracing_pid = self()

  Task.Supervisor.start_child(MyTaskSupervisor, fn ->

    AwsExRay.Process.keep_tracing(tracing_pid)

    current_trace = AwsExRay.start_subsegment("subsegment-name")

    do_some_work()

    case current_trace do
      {:ok, subsegment} ->
        AwsExRay.finish_subsegment(subsegment)

      {:error, :out_of_xray} -> :ok
    end

  end)
  ```
  """

  alias AwsExRay.Store

  @spec keep_tracing(pid) :: :ok | {:error, :out_of_xray}

  def keep_tracing(tracing_pid) do

    case Store.Table.lookup(tracing_pid) do

      {:ok, trace, segment_id, []} ->
        Store.Table.insert(trace, segment_id)
        Store.MonitorSupervisor.start_monitoring(self())
        :ok

      {:ok, trace, _segment_id, [current_id|_rest]} ->
        Store.Table.insert(trace, current_id)
        Store.MonitorSupervisor.start_monitoring(self())
        :ok

      {:error, :not_found} ->
        {:error, :out_of_xray}

    end

  end

end
