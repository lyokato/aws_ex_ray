defmodule AwsExRay.Context do

  alias AwsExRay.Client
  alias AwsExRay.Config
  alias AwsExRay.Segment
  alias AwsExRay.Trace

  defstruct trace: nil,

  def start_segment(ctx, name) do
    seg = Segment.build(name, ctx.trace_id)
    try do

    rescue
      err -> raise(err)
    after
      seg
      |> Segment.to_json()
      |> Client.send()
    end

  end

end
