defmodule AwsExRay.Record.HTTPResponse do

  @moduledoc ~S"""
  This module provides a data structure which represents **http.response** report.
  """

  @type t :: %__MODULE__{
    status: non_neg_integer,
    length: non_neg_integer,
  }

  defstruct status: 200,
            length: 0

  @spec new(
    status :: non_neg_integer,
    length :: non_neg_integer
  ) :: %__MODULE__{}

  def new(status, length) do
    %__MODULE__{status: status, length: length}
  end

  @spec to_map(%__MODULE__{}) :: map
  def to_map(res) do
    %{
      status:         res.status,
      content_length: res.length
    }
  end

end
