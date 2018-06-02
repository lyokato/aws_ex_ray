  defmodule AwsExRay.Util do

    @moduledoc """
    This module provides some utility functions
    """

    @spec now() :: float
    def now() do
      ms = DateTime.utc_now |> DateTime.to_unix(:microseconds)
      ms / 1_000_000
    end

    @spec generate_trace_id() :: String.t
    def generate_trace_id() do
      t = System.system_time(:seconds)
          |> Integer.to_string(16)
          |> String.downcase()
      "1-#{t}-#{SecureRandom.hex(12)}"
    end

    @spec generate_model_id() :: String.t
    def generate_model_id() do
      SecureRandom.hex(8)
    end

    @spec get_header(keyword, String.t, String.t) :: String.t
    def get_header(headers, name, default \\ "") do
      case Enum.filter(headers, fn {k, _} -> String.downcase(k) == name end) do
        [] -> default
        [header|_] -> header |> elem(1)
      end
    end

  end
