  defmodule AwsExRay.Subsegment.Formatter do

    def to_json(seg) do
      to_map(seg) |> Poison.encode!()
    end

    def to_map(seg) do

      m = AwsExRay.Segment.Formatter.to_map(seg.segment)

      put_in(m.type, "subsegment")
      |> embed_remote(seg)

      # TODO
      # sql
      # http.request.traced
    end

    defp embed_remote(m, seg) do
      if seg.remote do
        put_in(m.namespace, "remote")
      else
        m
      end
    end

  end
