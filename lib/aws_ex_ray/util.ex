  defmodule AwsExRay.Util do

    @moduledoc """
    This module provides some utility functions
    """

    @spec now() :: float
    def now() do
      ms = DateTime.utc_now |> DateTime.to_unix(:microsecond)
      ms / 1_000_000
    end

    @spec generate_trace_id() :: String.t
    def generate_trace_id() do
      t = DateTime.utc_now
          |> DateTime.to_unix(:second)
          |> Integer.to_string(16)
          |> String.downcase()
      "1-#{t}-#{SecureRandom.hex(12)}"
    end

    @spec generate_model_id() :: String.t
    def generate_model_id() do
      SecureRandom.hex(8)
    end

    @spec sample?() :: boolean
    @deprecated "Use sample?/1 instead"
    def sample?() do
      sample?(%{})
    end

    @spec sample?(AwsExRay.Trace.request_map) :: boolean
    def sample?(request) do
      rules = AwsExRay.Rules.get()
      AwsExRay.Rules.sample?(request, rules)
    end

    @spec get_header(keyword, String.t, String.t) :: String.t
    def get_header(headers, name, default \\ "") do
      case Enum.filter(headers, fn {k, _} -> String.downcase(k) == name end) do
        [] -> default
        [header|_] -> header |> elem(1)
      end
    end

  end
