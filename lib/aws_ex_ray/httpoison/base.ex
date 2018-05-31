defmodule AwsExRay.HTTPoison.Base do

  defmacro __using__(_opts) do

    quote do

      use HTTPoison.Base

      alias AwsExRay.Record.Error
      alias AwsExRay.Record.Error.Cause
      alias AwsExRay.Record.HTTPRequest
      alias AwsExRay.Record.HTTPResponse
      alias AwsExRay.Stacktrace
      alias AwsExRay.Subsegment
      alias AwsExRay.Util

      def request(method, url, body \\ "", headers \\ [], options \\ []) do

        case start_subsegment(headers, url) do

          {:error, :out_of_xray} ->

            super(method, url, body, headers, options)

          {:ok, subsegment} ->

            request_record = %HTTPRequest{
              segment_type: :subsegment,
              method:       String.upcase(to_string(method)),
              url:          url,
              traced:       Keyword.get(options, :traced, false),
              user_agent:   get_user_agent(headers)
            }

            subsegment =
              Subsegment.set_http_request(subsegment, request_record)

            headers = put_tracing_header(headers, subsegment)

            result = super(method, url, body, headers, options)

            subsegment = subsegment
                       |> put_response_record_if_needed(result)

            case result do

              {:ok, %HTTPoison.Response{status_code: code}} when code >=400 and code < 600 ->
                put_response_error(subsegment, code, Stacktrace.stacktrace())

              {:ok, _other} -> subsegment

              {:error, %HTTPoison.Error{reason: reason}} ->
                cause = Cause.new(:http_response_error, "#{reason}", Stacktrace.stacktrace())
                error = %Error{
                  cause:    cause,
                  throttle: false,
                  error:    false,
                  fault:    true,
                  remote:   false,
                }
                Subsegment.set_error(subsegment, error)

            end

            AwsExRay.finish_subsegment(subsegment)

            result


        end

      end

      defp put_response_error(seg, status, stack) do
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

      defp put_response_record_if_needed(subsegment, http_response) do
        case http_response do

          {:ok, %HTTPoison.Response{status_code: code, headers: headers}} ->
            res = HTTPResponse.new(code, get_response_content_length(headers))
            Subsegment.set_http_response(subsegment, res)

          {:error, error} ->
            subsegment

        end
      end

      defp start_subsegment(headers, url) do
        find_tracing_name(headers, url)
        |> AwsExRay.start_subsegment(namespace: :remote)
      end

      defp get_user_agent(headers) do
        Util.get_header(headers, "user-agent")
      end

      defp get_response_content_length(headers) do
        Util.get_header(headers, "content-length", "0") |> String.to_integer()
      end

      defp put_tracing_header(headers, subsegment) do
        value = Subsegment.generate_trace_value(subsegment)
        [{"X-Amzn-Trace-Id", value}|headers]
      end

      defp find_tracing_name(headers, url) do
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

  end

end
