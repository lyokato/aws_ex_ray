defmodule AwsExRay do

  require Logger

  alias AwsExRay.Client
  alias AwsExRay.Segment
  alias AwsExRay.Store
  alias AwsExRay.Subsegment
  alias AwsExRay.Trace

  @spec start_tracing(trace :: Trace.t, name :: String.t) :: Segment.t

  def start_tracing(trace, name) do

    segment = Segment.new(trace, name)

    Store.insert(trace, segment.id)

    segment

  end

  def finish_tracing(segment) do

    segment
    |> Segment.finish()
    |> Segment.to_json()
    |> Client.send()

    Store.delete()

    :ok

  end

  def start_subsegment(name) do
    start_subsegment(name, self())
  end

  def start_subsegment(name, pid) do

    # TODO
    remote = false

    case Store.lookup(pid) do

      {:ok, trace, segment_id} ->
        subsegment =
          %{trace|parent: segment_id}
          |> Subsegment.new(name, remote)
        {:ok, subsegment}

      {:error, :not_found} ->
        Logger.warn "<AwsExRay> subsegment couldn't be started. parent segment is not found on the process."
        {:error, :not_found}

    end

  end

  def finish_subsegment(subsegment) do

    subsegment
    |> Subsegment.finish()
    |> Subsegment.to_json()
    |> Client.send()

  end

end
