defmodule AwsExRay do

  require Logger

  alias AwsExRay.Client
  alias AwsExRay.Segment
  alias AwsExRay.Store
  alias AwsExRay.Subsegment
  alias AwsExRay.Trace
  alias AwsExRay.Util

  @spec start_tracing(trace :: Trace.t, name :: String.t) :: Segment.t

  def start_tracing(trace, name) do

    segment = Segment.new(trace, name)

    Store.Table.insert(trace, segment.id)
    Store.MonitorSupervisor.start_monitoring(self())

    segment

  end

  @spec finish_tracing(segment :: Sugment.t) :: :ok

  def finish_tracing(segment) do

    segment = segment
           |> Segment.finish()

    if Segment.sampled?(segment) do

      segment
      |> Segment.to_json()
      |> Client.send()

    end

    :ok

  end

  def start_subsegment(name, opts \\ []) do

    ns  = Keyword.get(opts, :namespace, :none)
    pid = Keyword.get(opts, :tracing_pid, self())

    case Store.Table.lookup(pid) do

      {:ok, trace, segment_id} ->
        subsegment = %{trace|parent: segment_id}
                   |> Subsegment.new(name, ns)
        {:ok, subsegment}

      {:error, :not_found} ->
        {:error, :out_of_xray}

    end
  end

  def finish_subsegment(subsegment, end_time \\ Util.now()) do

    subsegment = subsegment
               |> Subsegment.finish(end_time)

    if Subsegment.sampled?(subsegment) do

      subsegment
      |> Subsegment.to_json()
      |> Client.send()

    end

  end

end
