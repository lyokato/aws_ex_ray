defmodule AwsExRay.Record.Error.Cause do

  alias AwsExRay.Util

  defstruct id:      "",
            type:    "",
            message: "",
            stack:   []

  def new(type, message, stack) do
    %__MODULE__{
      id:        Util.generate_model_id(),
      type:      type,
      message:   message,
      stack:     stack,
    }
  end

  @spec to_map(cause :: %__MODULE__{}, remote :: boolean) :: map
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
