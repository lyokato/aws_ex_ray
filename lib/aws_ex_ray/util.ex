  defmodule AwsExRay.Util do

    def now() do
      System.system_time(:micro_seconds) / 1_000_000
    end

  end
