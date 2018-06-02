defmodule AwsExRay.HTTPClientUtil do

  @moduledoc """
  This module provides some utility functions for HTTP client
  """

  alias AwsExRay.Record.Error
  alias AwsExRay.Record.Error.Cause
  alias AwsExRay.Segment
  alias AwsExRay.Subsegment
  alias AwsExRay.Util

  @spec put_response_error(
    seg    :: Segment.t,
    status :: integer,
    stack  :: list
  ) :: Segment.t
  def put_response_error(seg, status, stack) do
    case status do

      code when code == 429 ->

        cause = Cause.new(:http_response_error, "Got 429", stack)
        error = %Error{
          cause:    cause,
          throttle: true,
          error:    true,
          fault:    false,
          remote:   true,
        }
        Subsegment.set_error(seg, error)

      code when code >= 400 and code < 500 ->
        cause = Cause.new(:http_response_error, "Got 4xx", stack)
        error = %Error{
          cause:    cause,
          throttle: false,
          error:    true,
          fault:    false,
          remote:   true,
        }
        Subsegment.set_error(seg, error)

      code when code >= 500 and code < 600 ->
        cause = Cause.new(:http_response_error, "Got 5xx", stack)
        error = %Error{
          cause:    cause,
          throttle: false,
          error:    false,
          fault:    true,
          remote:   true,
        }
        Subsegment.set_error(seg, error)

      _ ->
        seg

    end
  end

  @spec get_user_agent(keyword) :: String.t
  def get_user_agent(headers) do
    Util.get_header(headers, "user-agent")
  end

  @spec get_response_content_length(keyword) :: integer
  def get_response_content_length(headers) do
    headers |> Util.get_header("content-length", "0") |> String.to_integer()
  end

  @spec put_tracing_header(keyword, Subsegment.t) :: keyword
  def put_tracing_header(headers, subsegment) do
    value = Subsegment.generate_trace_value(subsegment)
    [{"X-Amzn-Trace-Id", value}|headers]
  end

  @spec find_tracing_name(keyword, String.t) :: String.t
  def find_tracing_name(headers, url) do
    name = Util.get_header(headers, "x-aws-xray-name")
    if name != "" do
      name
    else
      name = Util.get_header(headers, "host")
      if name != "" do
        name
      else
        name = find_host(url)
        if name != "" do
          name
        else
          to_string(__MODULE__)
        end
      end
    end
  end

  defp find_host(url) do
    parsed = URI.parse(url)
    if parsed != nil && parsed.host != nil do
      parsed.host
    else
      ""
    end
  end

end
