defmodule AwsExRay.Context do

  alias AwsExRay.Client
  alias AwsExRay.Config
  alias AwsExRay.Segment

  defstruct trace_id:          "",
            sampled:           true,
            parent_segment_id: ""

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{
      trace_id:          generate_trace_id(),
      sampled:           sample?(),
      parent_segment_id: "",
    }
  end

  def with_params(trace_id, sampled, parent) do
    %__MODULE__{
      trace_id:          trace_id,
      sampled:           sampled,
      parent_segment_id: parent
    }
  end

  defp generate_trace_id() do
    t = System.system_time(:seconds) |> Integer.to_string(16)
    "1-#{t}-#{SecureRandom.hex(12)}"
  end

  defp sample?() do
    :rand.uniform() > Config.sampling_rate
  end

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
