  defmodule AwsExRay.Subsegment do

    alias AwsExRay.Record.SQL
    alias AwsExRay.Segment
    alias AwsExRay.Subsegment.Formatter
    alias AwsExRay.Trace
    alias AwsExRay.Util

    @type namespace :: :none | :remote | :aws

    @type t :: %__MODULE__{
      segment:   Segment.t,
      namespace: namespace,
      sql:       SQL.t,
      aws:       map,
    }

    defstruct segment:   nil,
              namespace: :none,
              sql:       nil,
              aws:       nil,

    def new(trace, name, namespace \\ :none) do
      %__MODULE__{
        segment:   Segment.new(trace, name),
        namespace: namespace
        sql:       nil
      }
    end

    def set_start_time(seg, start_time) do
      put_in(seg.segment.start_time, start_time)
    end

    def get_trace(seg) do
      seg.segment.trace
    end

    def set_sql(seg, sql) do
      Map.put(seg, :sql, sql)
    end

    def set_http_request(seg, req) do
      put_in(seg.segment.http.request, req)
    end

    def set_http_response(seg, res) do
      put_in(seg.segment.http.response, res)
    end

    def generate_trace_value(seg) do
      trace = seg.segment.trace
      trace = %{trace|parent: seg.segment.id}
      Trace.Formatter.to_http_header(trace)
    end

    def sampled?(seg) do
      Segment.sampled?(seg.segment)
    end

    def finished?(seg) do
      seg.segment.end_time > 0
    end

    def finish(seg) do
      finish(seg, Util.now())
    end

    def finish(seg, end_time) do
      if finished?(seg) do
        seg
      else
        put_in(seg.segment.end_time, end_time)
      end
    end

    def to_json(seg), do: Formatter.to_json(seg)

  end
