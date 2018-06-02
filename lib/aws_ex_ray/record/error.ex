defmodule AwsExRay.Record.Error do

  @moduledoc ~S"""
  This module provides a data structure which represents **error** report.
  """

  alias AwsExRay.Record.Error.Cause

  @type t :: %__MODULE__{
    error:    boolean,
    throttle: boolean,
    fault:    boolean,
    remote:   boolean,
    cause:    Cause.t
  }

  defstruct error:    false,
            throttle: false,
            fault:    false,
            remote:   false,
            cause:    nil

  @spec to_map(err :: t) :: map
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
