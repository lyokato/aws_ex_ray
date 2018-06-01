defmodule AwsExRay.HTTPClientUtil do

  alias AwsExRay.Record.Error
  alias AwsExRay.Record.Error.Cause
  alias AwsExRay.Subsegment
  alias AwsExRay.Util

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

  def get_user_agent(headers) do
    Util.get_header(headers, "user-agent")
  end

  def get_response_content_length(headers) do
    Util.get_header(headers, "content-length", "0") |> String.to_integer()
  end

  def put_tracing_header(headers, subsegment) do
    value = Subsegment.generate_trace_value(subsegment)
    [{"X-Amzn-Trace-Id", value}|headers]
  end

  def find_tracing_name(headers, url) do
    headers = headers |> Map.new(&{elem(&1,0), elem(&1,1)})
    case Map.get(headers, "X-Aws-Xray-Name") do

      nil ->
        case Map.get(headers, "Host") do

          nil ->
            parsed = URI.parse(url)
            if parsed.host == nil do
              to_string(__MODULE__)
            else
              parsed.host
            end

          host -> host
        end

      name -> name

    end

  end

end
