defmodule AwsExRay.Trace do

  alias AwsExRay.Config
  alias AwsExRay.Util

  @type t :: %__MODULE__{
    root:    String.t,
    sampled: boolean,
    parent:  String.t
  }

  defstruct root:     "",
            sampled:  true,
            parent:   ""

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{
      root:    Util.generate_trace_id(),
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

  defp sample?() do
    :rand.uniform() > Config.sampling_rate
  end

end
