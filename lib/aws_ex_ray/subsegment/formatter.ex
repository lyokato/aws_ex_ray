  defmodule AwsExRay.Subsegment.Formatter do

    alias AwsExRay.Record.SQL

    def to_json(seg) do
      to_map(seg) |> Poison.encode!()
    end

    def to_map(seg) do

      m = AwsExRay.Segment.Formatter.to_map(seg.segment)

      Map.put(m, :type, "subsegment")
      |> embed_namespace(seg)
      |> embed_sql(seg)

    end

    defp embed_sql(m, seg) do
      if seg.sql != nil do
        Map.put(m, :sql, SQL.to_map(seg.sql))
      else
        m
      end
    end

    defp embed_namespace(m, seg) do
      if seg.namespace == :none do
        m
      else
        Map.put(m, :namespace, seg.namespace)
      end
    end

  end
