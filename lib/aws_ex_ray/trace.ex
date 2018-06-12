defmodule AwsExRay.Trace do

  @moduledoc ~S"""
  This module provides data structure which represents X-Ray's **trace**
  """

  alias AwsExRay.Trace
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

  @spec new() :: t
  def new() do
    %__MODULE__{
      root:    Util.generate_trace_id(),
      sampled: Util.sample?(),
      parent:  "",
    }
  end

  @spec with_params(
    trace_id :: String.t,
    sampled  :: boolean,
    parent   :: String.t
  ) :: t
  def with_params(trace_id, sampled, parent) do
    %__MODULE__{
      root:     trace_id,
      sampled:  sampled,
      parent:   parent
    }
  end

  @spec parse(String.t) :: {:ok, Trace.t} | {:error, :not_found}
  def parse(value), do: Formatter.parse(value)

  @spec parse_or_new(String.t) :: Trace.t
  def parse_or_new(value) do
    case parse(value) do
      {:ok, trace}         -> trace
      {:error, :not_found} -> new()
    end
  end

  @spec to_string(t) :: String.t
  def to_string(trace), do: Formatter.to_string(trace)

end

defimpl String.Chars, for: AwsExRay.Trace do

  alias AwsExRay.Trace

  def to_string(%Trace{} = trace) do
    Trace.to_string(trace)
  end

end
