defmodule AwsExRay.Trace do

  alias AwsExRay.Config
  alias AwsExRay.Trace.Formatter
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
    :rand.uniform() <= Config.sampling_rate
  end

  def parse(value), do: Formatter.parse(value)
  def to_string(trace), do: Formatter.to_string(trace)

end

defimpl String.Chars, for: AwsExRay.Trace do

  alias AwsExRay.Trace

  def to_string(%Trace{}=trace) do
    Trace.to_string(trace)
  end

end
