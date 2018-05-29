defmodule AwsExRay.Context do

  alias AwsExRay.Client
  alias AwsExRay.Segment

  defstruct trace: nil

  def new(trace) do
    %__MODULE__{trace: trace}
  end

  def start_segment(ctx, name) do
    Segment.build(name, ctx.trace.root)
  end

  def finish_segment(ctx, seg) do
    Segment.finish(seg)
    |> Segment.to_json()
    |> Client.send()
  end

end
