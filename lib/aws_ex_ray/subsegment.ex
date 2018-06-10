  defmodule AwsExRay.Subsegment do

    @moduledoc ~S"""
    This module provides data structure which represents X-Ray's **subsegment**
    """

    alias AwsExRay.Record.Error
    alias AwsExRay.Record.SQL
    alias AwsExRay.Record.HTTPRequest
    alias AwsExRay.Record.HTTPResponse
    alias AwsExRay.Segment
    alias AwsExRay.Subsegment.Formatter
    alias AwsExRay.Trace
    alias AwsExRay.Util

    @type namespace :: :none | :remote | :aws

    @type t :: %__MODULE__{
      segment:   Segment.t,
      namespace: namespace,
      sql:       SQL.t | nil,
      aws:       map | nil,
    }

    defstruct segment:   nil,
              namespace: :none,
              sql:       nil,
              aws:       nil

    @spec new(
      trace     :: Trace.t,
      name      :: String.t,
      namespace :: namespace
    ) :: t
    def new(trace, name, namespace \\ :none) do
      %__MODULE__{
        segment:   Segment.new(trace, name),
        namespace: namespace,
        sql:       nil,
        aws:       nil
      }
    end

    @spec id(seg :: t) :: String.t
    def id(seg), do: seg.segment.id

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
      annotation = seg.segment.annotation
      annotation = Map.put(annotation, key, value)
      put_in(seg.segment.annotation, annotation)
    end

    @spec set_aws(seg :: t, params :: map) :: t
    def set_aws(seg, params) do
      Map.put(seg, :aws, params)
    end

    @spec set_start_time(seg :: t, start_time :: float) :: t
    def set_start_time(seg, start_time) do
      put_in(seg.segment.start_time, start_time)
    end

    @spec get_trace(seg :: t) :: Trace.t
    def get_trace(seg) do
      seg.segment.trace
    end

    @spec set_sql(seg :: t, sql :: SQL.t) :: t
    def set_sql(seg, sql) do
      Map.put(seg, :sql, sql)
    end

    @spec set_http_request(seg :: t, req :: HTTPRequest.t) :: t
    def set_http_request(seg, req) do
      put_in(seg.segment.http.request, req)
    end

    @spec set_http_response(seg :: t, res :: HTTPResponse.t) :: t
    def set_http_response(seg, res) do
      put_in(seg.segment.http.response, res)
    end

    @spec set_error(seg :: t, error :: Error.t) :: t
    def set_error(seg, error) do
      put_in(seg.segment.error, error)
    end

    @spec generate_trace_value(seg :: t) :: String.t
    def generate_trace_value(seg) do
      trace = seg.segment.trace
      trace = %{trace|parent: seg.segment.id}
      Trace.to_string(trace)
    end

    @spec sampled?(seg :: t) :: boolean
    def sampled?(seg) do
      Segment.sampled?(seg.segment)
    end

    @spec finished?(seg :: t) :: boolean
    def finished?(seg) do
      seg.segment.end_time > 0
    end

    @spec finish(seg :: t, end_time :: float) :: t
    def finish(seg, end_time \\ Util.now()) do
      if finished?(seg) do
        seg
      else
        put_in(seg.segment.end_time, end_time)
      end
    end

    @spec to_json(seg :: t) :: String.t
    def to_json(seg), do: Formatter.to_json(seg)

  end
