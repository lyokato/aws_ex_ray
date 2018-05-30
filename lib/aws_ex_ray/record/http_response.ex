defmodule AwsExRay.Record.HTTPResponse do

  defstruct status: 200,
            length: 0

  def new(status, length) do
    %__MODULE__{status: status, length: length}
  end

  def to_map(res) do
    %{
      status:         res.status,
      content_length: res.length
    }
  end

end
