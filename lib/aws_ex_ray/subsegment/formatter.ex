  defmodule AwsExRay.Subsegment.Formatter do

    @moduledoc ~S"""
    This module provides a formatter functions
    for subsegment record
    """

    alias AwsExRay.Record.SQL

    def to_json(seg) do
      seg |> to_map() |> Poison.encode!()
    end

    def to_map(seg) do

      seg.segment
      |> AwsExRay.Segment.Formatter.to_map()
      |> Map.put(:type, "subsegment")
      |> embed_namespace(seg)
      |> embed_sql(seg)
      |> embed_aws(seg)

    end

    defp embed_aws(m, seg) do
      if seg.aws != nil do
        Map.put(m, :aws, seg.aws)
      else
        m
      end
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
