  defmodule AwsExRay.Subsegment do

    alias AwsExRay.Segment
    alias AwsExRay.Subsegment.Formatter
    alias AwsExRay.Util

    @type t :: %__MODULE__{
      segment: Segment.t,
      remote:  boolean
    }

    defstruct segment: nil,
              remote:  false

    def new(trace, name, remote) do
      %__MODULE__{
        segment: Segment.new(trace, name),
        remote:  remote
      }
    end

    def sampled?(seg) do
      Segment.sampled?(seg.segment)
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
