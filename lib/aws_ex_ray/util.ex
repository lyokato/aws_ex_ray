  defmodule AwsExRay.Util do

    def now() do
      System.system_time(:micro_seconds) / 1_000_000
    end

    defp generate_trace_id() do
      t = System.system_time(:seconds) |> Integer.to_string(16)
      "1-#{t}-#{SecureRandom.hex(12)}"
    end

    def generate_model_id() do
      SecureRandom.hex(8)
    end

  end
