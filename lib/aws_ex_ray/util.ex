  defmodule AwsExRay.Util do

    def now() do
      System.system_time(:micro_seconds) / 1_000_000
    end

    def generate_trace_id() do
      t = System.system_time(:seconds)
          |> Integer.to_string(16)
          |> String.downcase()
      "1-#{t}-#{SecureRandom.hex(12)}"
    end

    def generate_model_id() do
      SecureRandom.hex(8)
    end

    def get_header(headers, name, default \\ "") do
      case Enum.filter(headers, fn {k, _} -> String.downcase(k) == name end) do
        [] -> default
        [header|_] -> header |> elem(1)
      end
    end

  end
