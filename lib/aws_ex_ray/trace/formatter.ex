defmodule AwsExRay.Trace.Formatter do

  def parse_http_header(header) do

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

  defp parse_to_map(header) do

    String.split(header, ";")
    |> Enum.map(&String.split(&1, "="))
    |> Map.new(fn [k, v] ->

      {String.downcase(k), v}

    end)

  end

  def to_http_header(trace) do
    "Root=#{trace.root}"
    |> add_parent_if_needed(trace.parent)
    |> add_sampled_if_needed(trace.sampled)
  end

  defp add_parent_if_needed(value, ""), do: value
  defp add_parent_if_needed(value, parent), do: value <> ";Parent=#{parent}"

  defp add_sampled_if_needed(value, false), do: value
  defp add_sampled_if_needed(value, true), do: value <> ";Sampled=1"

end
