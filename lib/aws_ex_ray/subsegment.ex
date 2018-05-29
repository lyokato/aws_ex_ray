  defmodule AwsExRay.Subsegment do

    alias AwsExRay.Segment
    alias AwsExRay.Subsegment.Formatter
    alias AwsExRay.Util

    defstruct segment: nil,
              remote:  false

    def build(name, trace_id, parent_id, remote) do
      %__MODULE__{
        segment: Segment.build(name, trace_id, parent_id),
        remote:  remote
      }
    end

    def finished?(seg) do
      seg.segment.end_time > 0
    end

    def finish(seg) do
      if finished?(seg) do
        seg
      else
        put_in(seg.segment.end_time, Util.now())
      end
    end

    def to_json(seg), do: Formatter.to_json(seg)

  end
