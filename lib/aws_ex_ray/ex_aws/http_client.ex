defmodule AwsExRay.ExAws.HTTPClient do

  @behaviour ExAws.Request.HttpClient

  alias AwsExRay.ExAws.WhiteList
  alias AwsExRay.HTTPClientUtil
  alias AwsExRay.Record.Error
  alias AwsExRay.Record.Error.Cause
  alias AwsExRay.Record.HTTPResponse
  alias AwsExRay.Subsegment
  alias AwsExRay.Stacktrace
  alias AwsExRay.Util

  @impl ExAws.Request.HttpClient
  def request(method, url, body \\ "", headers \\ [], opts \\ []) do

    {service, operation} = parse_target(headers)

    case AwsExRay.start_subsegment(service, namespace: :aws) do

      {:error, :out_of_xray} ->
        HTTPoison.request(method, url, body, headers, opts)

      {:ok, subsegment} ->

        {service, operation} = parse_target(headers)

        whitelist = WhiteList.find(service, operation)

        aws_req_params = gather_aws_request_params(whitelist, body)

        headers = HTTPClientUtil.put_tracing_header(headers, subsegment)
        headers = [{"X-Amzn-Xray-Name", service}|headers]

        result = HTTPoison.request(method, url, body, headers, opts)

        subsegment = case result do

          {:ok, %HTTPoison.Response{status_code: code, headers: headers, body: body}} ->

            len = HTTPClientUtil.get_response_content_length(headers)
            res = HTTPResponse.new(code, len)

            subsegment = Subsegment.set_http_response(subsegment, res)

            aws_res_params = gather_aws_response_params(whitelist, body)

            request_id = Util.get_header(headers, "x-amzn-RequestId")

            aws = %{
              request_id: request_id,
              operation:  operation,
            }
            |> Map.merge(aws_req_params)
            |> Map.merge(aws_res_params)

            subsegment = Subsegment.set_aws(subsegment, aws)

            if code >= 400 and code < 600 do
              HTTPClientUtil.put_response_error(subsegment,
                                                code,
                                                Stacktrace.stacktrace())
            else
              subsegment
            end

          {:error, %HTTPoison.Error{reason: reason}} ->
            cause = Cause.new(:http_response_error,
                              "#{reason}",
                              Stacktrace.stacktrace())
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

  defp gather_aws_response_params(_whitelist, ""), do: %{}
  defp gather_aws_response_params(whitelist, body) do
    case Poison.decode(body) do
      {:ok, json} ->
        WhiteList.gather(:response, json, whitelist)

      _ -> %{}
    end
  end

  defp gather_aws_request_params(_whitelist, ""), do: %{}
  defp gather_aws_request_params(whitelist, body) do
    case Poison.decode(body) do

      {:ok, json} ->
        WhiteList.gather(:request, json, whitelist)

      _ -> %{}

    end
  end

  defp parse_target(headers) do
    case headers |> Util.get_header("x-amz-target") |> String.split(".") do
      [svc_and_ver, operation] ->
        case String.split(svc_and_ver, "_") do
          [svc, _ver] -> {svc, operation}
          _ -> raise_invalid_target()
        end
      _ -> raise_invalid_target()
    end
  end

  defp raise_invalid_target() do
    raise "valid X-Amz-Target not found"
  end

end
