defmodule AwsExRay.Trace.Formatter do

  @moduledoc ~S"""
  This module provides parser and formatter functions
  for X-Ray Trace information
  """

  alias AwsExRay.Trace

  @spec parse(header :: String.t)
  :: {:ok, Trace.t}
  |  {:error, :not_found}

  def parse(header) do

    m = parse_to_map(header)

    if Map.has_key?(m, "root") do

      root    = Map.get(m, "root")
      parent  = Map.get(m, "parent", "")
      sampled = Map.get(m, "sampled", "0") == "1"

      trace = AwsExRay.Trace.with_params(
        root,
        sampled,
        parent
      )

      {:ok, trace}

    else

      {:error, :not_found}

    end

  end

  defp parse_to_map(nil), do: %{}
  defp parse_to_map(""), do: %{}
  defp parse_to_map(header) do

    header
    |> String.split(";")
    |> Enum.map(&String.split(&1, "="))
    |> Map.new(fn [k, v] ->

      {String.downcase(k), v}

    end)

  end

  @spec to_string(Trace.t) :: String.t
  def to_string(trace) do
    "Root=#{trace.root}"
    |> add_parent_if_needed(trace.parent)
    |> add_sampled_if_needed(trace.sampled)
  end

  defp add_parent_if_needed(value, ""), do: value
  defp add_parent_if_needed(value, parent), do: value <> ";Parent=#{parent}"

  defp add_sampled_if_needed(value, false), do: value <> ";Sampled=0"
  defp add_sampled_if_needed(value, true), do: value <> ";Sampled=1"

end
