defmodule AwsExRay.Trace do

  @moduledoc ~S"""
  This module provides data structure which represents X-Ray's **trace**
  """

  alias AwsExRay.Trace
  alias AwsExRay.Trace.Formatter
  alias AwsExRay.Util

  @type t :: %__MODULE__{
    root:    String.t,
    sampled: boolean | :undefined,
    parent:  String.t
  }

  @type request_map :: %{
    optional(:service_name | :service_type | :http_method | :host | :url_path | :resource_arn) => string()
  }

  defstruct root:     "",
            sampled:  true,
            parent:   ""

  @spec new() :: t
  @deprecated "Use new/1 instead"
  def new() do
    new(%{})
  end

  @spec new(request_map) :: t
  def new(request) do
    %__MODULE__{
      root:    Util.generate_trace_id(),
      sampled: Util.sample?(request),
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

  @spec parse_or_new(String.t, request_map) :: Trace.t
  def parse_or_new(value, request \\ %{}) do
    case parse(value) do
      {:ok, %__MODULE__{sampled: :undefined} = trace} ->
        %{trace | sampled: Util.sample?(request)}
      {:ok, %__MODULE__{sampled: sampled} = trace} when is_boolean(sampled) ->
        trace
      {:error, :not_found} ->
        new(request)
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
