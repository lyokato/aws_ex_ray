  defmodule AwsExRay.Segment do

  @moduledoc ~S"""
  This module provides data structure which represents X-Ray's **segment**
  """

    alias AwsExRay.Config
    alias AwsExRay.Segment.Formatter
    alias AwsExRay.Trace
    alias AwsExRay.Util
    alias AwsExRay.Record.HTTPRequest
    alias AwsExRay.Record.HTTPResponse
    alias AwsExRay.Record.Error

    @type t :: %__MODULE__{
      id:         String.t,
      name:       String.t,
      version:    String.t,
      trace:      Trace.t,
      start_time: float,
      end_time:   float,
      annotation: map,
      metadata:   map,
      error:      map | nil,
      http:       map
    }

    defstruct id:         "",
              name:       "",
              version:    "",
              trace:      nil,
              start_time: 0.0,
              end_time:   0.0,
              error:      %{},
              annotation: %{},
              metadata:   %{},
              http: %{}

    @spec new(trace :: Trace.t, name :: String.t) :: t
    def new(trace, name) do
      trace_sampled =
        case trace.sampled do
          :undefined ->
            # If the trace doesn't specify whether it's sampled,
            # we'll need to make a decision one way or the other.
            %{trace | sampled: Util.sample?()}
          sampled when is_boolean(sampled) ->
            trace
        end
      %__MODULE__{
        id:         Util.generate_model_id(),
        name:       name,
        version:    Config.service_version(),
        trace:      trace_sampled,
        start_time: Util.now(),
        error:      nil,
        end_time:   0.0,
        annotation: %{} |> Map.merge(Config.default_annotation),
        metadata: %{
          tracing_sdk: %{
            name:    Config.library_name,
            version: Config.library_version,
          }
        } |> Map.merge(Config.default_metadata),
        http: %{
          request: nil,
          response: nil
        }
      }
    end

    @spec add_annotations(
      seg         :: t,
      annotations :: map
    ) :: t
    def add_annotations(seg, annotations) do
      annotations
      |> Enum.reduce(seg, fn {key, value}, seg ->
        add_annotation(seg, key, value)
      end)
    end

    @spec add_annotation(
      seg   :: t,
      key   :: atom | String.t,
      value :: any
    ) :: t
    def add_annotation(seg, key, value) do
      annotation = seg.annotation
      annotation = Map.put(annotation, key, value)
      Map.put(seg, :annotation, annotation)
    end

    @spec set_http_request(seg :: t, req :: HTTPRequest.t) :: t
    def set_http_request(seg, req) do
      put_in(seg.http.request, req)
    end

    @spec set_http_request(seg :: t, res :: HTTPResponse.t) :: t
    def set_http_response(seg, res) do
      put_in(seg.http.response, res)
    end

    @spec set_error(seg :: t, error :: Error.t) :: t
    def set_error(seg, error) do
      Map.put(seg, :error, error)
    end

    @spec generate_trace_value(seg :: t) :: String.t
    def generate_trace_value(seg) do
      trace = seg.trace
      trace = %{trace|parent: seg.id}
      Trace.to_string(trace)
    end

    @spec sampled?(seg :: t) :: boolean
    def sampled?(seg) do
      seg.trace.sampled
    end

    @spec finished?(seg :: t) :: boolean
    def finished?(seg) do
      seg.end_time > 0
    end

    @spec finish(seg :: t) :: t
    def finish(seg) do
      if finished?(seg) do
        seg
      else
        %{seg|end_time: Util.now()}
      end
    end

    @spec to_json(seg :: t) :: String.t
    def to_json(seg), do: Formatter.to_json(seg)

  end
