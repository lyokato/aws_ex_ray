defmodule AwsExRay.Record.SQL do

  defstruct url:               nil,
            database_version:  nil,
            database_type:     nil,
            sanitized_query:   nil,
            connection_string: nil,
            driver_version:    nil,
            preparation:       nil

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
