defmodule AwsExRay.Trace do

  alias AwsExRay.Config

  defstruct root:     "",
            sampled:  true,
            parent:   ""

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{
      root:    generate_trace_id(),
      sampled: sample?(),
      parent:  "",
    }
  end

  @spec with_params(
    trace_id :: String.t,
    sampled  :: boolean,
    parent   :: String.t
  ) :: %__MODULE__{}
  def with_params(trace_id, sampled, parent) do
    %__MODULE__{
      root:     trace_id,
      sampled:  sampled,
      parent:   parent
    }
  end

  defp generate_trace_id() do
    t = System.system_time(:seconds) |> Integer.to_string(16)
    "1-#{t}-#{SecureRandom.hex(12)}"
  end

  defp sample?() do
    :rand.uniform() > Config.sampling_rate
  end

end
