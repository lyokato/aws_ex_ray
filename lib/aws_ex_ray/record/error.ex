defmodule AwsExRay.Record.Error do

  alias AwsExRay.Record.Error.Cause

  defstruct error:    false,
            throttle: false,
            fault:    false,
            remote:   false,
            cause:    nil

  def to_map(err) do
    %{
      error:    err.error,
      throttle: err.throttle,
      fault:    err.fault,
    }
    |> embed_cause(err)
  end

  defp embed_cause(m, err) do
    if err.cause != nil do
      Map.put(m, :cause, Cause.to_map(err.cause, err.remote))
    else
      m
    end
  end

end
