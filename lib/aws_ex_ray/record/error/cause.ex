defmodule AwsExRay.Record.Error.Cause do

  defstruct id: "",
            working_directory: "./",
            stack:   [],
            message: "",
            type:    ""

  @spec to_map(remote :: boolean) :: map
  def to_map(remote) do

  end

end
