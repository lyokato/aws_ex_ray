defmodule AwsExRay.Record.HTTPRequest do

  @moduledoc ~S"""
  This module provides a data structure which represents **http.request** report.
  """

  @type segment_type :: :segment | :subsegment

  @type t :: %__MODULE__{
    segment_type:    segment_type,
    method:          String.t | atom,
    url:             String.t,
    user_agent:      String.t,
    client_ip:       String.t,
    x_forwarded_for: boolean, # segment only
    traced:          boolean  # subsegment only
  }

  defstruct segment_type:    :segment,
            method:          nil,
            url:             nil,
            user_agent:      nil,
            client_ip:       nil,
            x_forwarded_for: false, # segment only
            traced:          false  # subsegment only

  @spec to_map(%__MODULE__{}) :: map
  def to_map(req) do

    m = [:method, :url, :user_agent, :client_ip]
        |> Enum.reduce(%{}, &(put_if_exists(&2, req, &1)))

    if req.segment_type == :segment do
      Map.put(m, :x_forwarded_for, req.x_forwarded_for)
    else
      Map.put(m, :traced, req.traced)
    end

  end

  defp put_if_exists(m, req, key) do
    value = Map.get(req, key)
    if value != nil && value != "" do
      Map.put(m, key, value)
    else
      m
    end
  end

end
