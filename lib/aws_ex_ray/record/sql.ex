defmodule AwsExRay.Record.SQL do

  @moduledoc ~S"""
  This module provides a data structure which represents **sql** report.
  """

  @type t :: %__MODULE__{
    url:               String.t | nil,
    database_version:  String.t | nil,
    database_type:     String.t | nil,
    sanitized_query:   String.t | nil,
    connection_string: String.t | nil,
    driver_version:    String.t | nil,
    preparation:       String.t | nil
  }

  defstruct url:               nil,
            database_version:  nil,
            database_type:     nil,
            sanitized_query:   nil,
            connection_string: nil,
            driver_version:    nil,
            preparation:       nil

  @spec to_map(sql :: t) :: map
  def to_map(sql) do
    [
      :url,
      :database_version,
      :database_type,
      :sanitized_query,
      :connection_string,
      :driver_version,
      :preparation,
    ]
    |> Enum.reduce(%{}, &(put_if_exists(&2, sql, &1)))
  end

  defp put_if_exists(m, sql, key) do
    value = Map.get(sql, key)
    if value != nil && value != "" do
      Map.put(m, key, value)
    else
      m
    end
  end

end
