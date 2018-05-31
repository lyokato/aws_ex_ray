defmodule AwsExRay.ExAws.HTTPClient do

  @behaviour ExAws.Request.HttpClient

  # HTTPベースのAWSマネージドサービスを使う場合
  # subsegmentのnamespaceは、'remote'ではなく'aws'になる
  # http.requestは外してhttp.responseだけをつける
  alias AwsExRay.Util
  alias AwsExRay.ExAws.WhiteList

  @impl ExAws.Request.HttpClient
  def request(method, url, body, headers, opts) do

    {service, operation} = parse_target(headers)
    params = Poison.decode!(body)
    aws_record = gather_operation_params(service, operation, params)
    aws_record = Map.put(aws_record, :operation, operation)
    #aws_record = Map.put(aws_record, :request_id, operation)

    # name - service

    headers = [{"X-Amzn-Xray-Name", service}|headers]
    AwsExRay.HTTPoison.request(method, url, body, headers, opts)

  end

  defp gather_operation_params(service, operation, _params) do
    case find_whitelist(service, operation) do
      {:ok, _whitelist} -> %{} # TODO
      {:error, :not_found} -> %{}
    end
  end

  defp find_whitelist(service, operation) do
    case Map.get(WhiteList.get(), String.downcase(service)) do
      service_params when is_map(service_params) ->
        case Map.get(service_params, operation) do
          operation_params when is_map(operation_params) ->
            {:ok, operation_params}
          nil -> {:error, :not_found}
        end
      nil -> {:error, :not_found}
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
