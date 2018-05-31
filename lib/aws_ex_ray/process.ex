defmodule AwsExRay.Process do

  alias AwsExRay.Store

  def keep_tracing(tracing_pid) do

    case Store.Table.lookup(tracing_pid) do

      {:ok, trace, segment_id} ->
        Store.Table.insert(trace, segment_id)
        Store.MonitorSupervisor.start_monitoring(self())
        :ok

      {:error, :not_found} ->
        {:error, :out_of_xray}

    end

  end

end
