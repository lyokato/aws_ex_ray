  defmodule AwsExRay.Segment.Formatter do

    alias AwsExRay.Segment

    def to_json(seg) do
      to_map(seg) |> Poison.encode!()
    end

    def to_map(seg) do
      %{
        name:        seg.name,
        id:          seg.id,
        trace_id:    seg.trace.root,
        start_time:  seg.start_time,
        #annotations: seg.annotations,
        metadata:    seg.metadata
      }
      |> embed_version(seg)
      |> embed_progress(seg)
      |> embed_parent(seg)
    end

    defp embed_parent(m, seg) do
      if seg.trace.parent != "" do
        Map.put(m, "parent_id", seg.trace.parent)
      else
        m
      end
    end

    defp embed_version(m, seg) do
      if seg.version != "" do
        Map.put(m, "service", %{"version" => seg.version})
      else
        m
      end
    end

    defp embed_progress(m, seg) do
      if Segment.finished?(seg) do
        Map.put(m, "in_progress", true)
      else
        Map.put(m, "end_time", seg.end_time)
      end
    end

  end
