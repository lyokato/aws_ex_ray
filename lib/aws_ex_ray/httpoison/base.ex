defmodule AwsExRay.HTTPoison.Base do

  defmacro __using__(_opts) do

    quote do

      use HTTPoison.Base

      alias AwsExRay.Model.HTTPRequest
      alias AwsExRay.Subsegment
      alias AwsExRay.Trace
      #alias AwsExRay.Model.HTTPResponse

      #defoverridable [
      #  request: 5
      #]

      def request(method, url, body \\ "", headers \\ [], options \\ []) do

        # TODO stuf request information
        request_record = %HTTPRequest{}

        subsegment = find_tracing_name(headers, url)
                   |> AwsExRay.start_subsegment(true)
                   |> Subsegment.set_http_request(request_record)


        headers = put_tracing_header(headers, subsegment)
        result = super(method, url, body, headers, options)

        # TODO put HTTPResponse into subsegment?

        AwsExRay.finish_subsegment(subsegment)

        result

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
