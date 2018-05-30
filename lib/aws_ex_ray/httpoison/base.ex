defmodule AwsExRay.HTTPoison.Base do

  defmacro __using__(_opts) do

    quote do

      use HTTPoison.Base

      alias AwsExRay.Record.HTTPRequest
      alias AwsExRay.Record.HTTPResponse
      alias AwsExRay.Subsegment
      alias AwsExRay.Trace

      #defoverridable [
      #  request: 5
      #]

      def request(method, url, body \\ "", headers \\ [], options \\ []) do

        request_record = %HTTPRequest{
          segment_type: :subsegment,
          method:       String.upcase(to_string(method)),
          url:          url
        }

        # TODO put 'use_agent'

        # TODO put 'traced' if needed
        # USE ORIGINAL options

        subsegment = find_tracing_name(headers, url)
                   |> AwsExRay.start_subsegment(true)
                   |> Subsegment.set_http_request(request_record)


        headers = put_tracing_header(headers, subsegment)
        result = super(method, url, body, headers, options)

        subsegment = case result do

          {:ok, %HTTPoison.Response{status_code: code, headers: headers}} ->
            res = HTTPResponse.new(code, get_response_content_length(headers))
            Subsegment.set_http_response(subsegment, res)

          {:error, error} ->
            # TODO
            subsegment

        end

        require Logger
        Logger.warn "HTTP: #{inspect result}"

        AwsExRay.finish_subsegment(subsegment)

        result

      end

      defp get_response_content_length(headers) do
        case headers |> Enum.filter(fn({k, _}) -> String.downcase(k) == "content-length" end) do
          [] -> 0
          [header|_] -> header |> elem(1) |> String.to_integer()
        end
      end

      defp put_tracing_header(headers, subsegment) do
        trace = Subsegment.get_trace(subsegment)
        value = Trace.Formatter.to_http_header(trace)
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
