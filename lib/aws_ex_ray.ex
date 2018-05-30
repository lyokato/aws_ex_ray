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

  @spec finish_tracing(segment :: Sugment.t) :: :ok

  def finish_tracing(segment) do

    segment = segment
           |> Segment.finish()

    if Segment.sampled?(segment) do

      segment
      |> Segment.to_json()
      |> Client.send()

    end

    Store.delete()

    :ok

  end

  def start_subsegment(name) do
    start_subsegment(name, false)
  end

  def start_subsegment(name, remote) do
    case Store.lookup() do

      {:ok, trace, segment_id} ->
        %{trace|parent: segment_id}
        |> Subsegment.new(name, remote)

      {:error, :not_found} ->
        raise "<AwsExRay> subsegment couldn't be started. tracing context is not found on this process."

    end
  end

  def finish_subsegment(subsegment) do

    subsegment = subsegment
               |> Subsegment.finish()

    if Subsegment.sampled?(subsegment) do

      subsegment
      |> Subsegment.to_json()
      |> Client.send()

    end

  end

  def current_context(), do: Store.lookup()
  def keep_context({trace, segment_id}) do
    Store.insert(trace, segment_id)
  end

end
