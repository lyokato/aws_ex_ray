defmodule AwsExRay.Record.Error.Cause do

  @moduledoc ~S"""
  This module provides a data structure which represents **error.cause** report.
  """

  alias AwsExRay.Util

  @type t :: %__MODULE__{
    id:      String.t,
    type:    atom,
    message: String.t,
    stack:   list
  }

  defstruct id:      "",
            type:    :exception,
            message: "",
            stack:   []

  @spec new(atom, String.t, list) :: t
  def new(type, message, stack) do
    %__MODULE__{
      id:        Util.generate_model_id(),
      type:      type,
      message:   message,
      stack:     stack,
    }
  end

  @spec to_map(cause :: t, remote :: boolean) :: map
  def to_map(cause, remote \\ false) do
    %{
      working_directory: cwd(),
      paths: [],
      exceptions: [
        %{
          id:        cause.id,
          message:   cause.message,
          type:      cause.type,
          truncated: 0,
          stack:     cause.stack,
          remote:    remote
        }
      ]
    }
  end

  defp cwd() do
    case System.cwd() do
      nil -> ""
      dir -> dir
    end
  end

end
