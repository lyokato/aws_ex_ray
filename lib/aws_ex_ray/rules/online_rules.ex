defmodule AwsExRay.Rules.OnlineRules do

  @moduledoc """
  Request sampling rules from and submit statistics to AWS X-Ray
  """

  require Logger

  @behaviour AwsExRay.Rules.Client.Behaviour

  @impl true
  def get_sampling_rules() do
    op = %ExAws.Operation.JSON{
      service: :xray,
      http_method: :post,
      path: "/GetSamplingRules"}
    config_overrides = xray_daemon_config()
    case request_all_rules(op, config_overrides, nil, []) do
      {:error, error} ->
        Logger.error("X-Ray GetSamplingRules request failed: #{inspect(error)}")
        {:error, error}
      {:ok, rule_records} ->
        {:ok, rule_records}
    end
  end

  defp request_all_rules(op, config_overrides, next_token, acc) do
    op = %{op | data: %{next_token: next_token}}
    case ExAws.request(op, config_overrides) do
      {:error, _} = error_response ->
        error_response
      {:ok, result} ->
        sampling_rule_records = result["SamplingRuleRecords"]
        new_acc = sampling_rule_records ++ acc
        case result["NextToken"] do
          nil ->
            # no more rules to request
            {:ok, new_acc}
          new_next_token ->
            request_all_rules(op, config_overrides, new_next_token, new_acc)
        end
    end
  end

  @impl true
  def post_statistics(statistics) do
    data = %{"SamplingStatisticsDocuments" => statistics}
    Logger.debug("About to send statistics: #{inspect(data)}")
    op = %ExAws.Operation.JSON{
      service: :xray,
      http_method: :post,
      path: "/SamplingTargets",
      data: data}
    case ExAws.request(op, xray_daemon_config()) do
      {:error, error} ->
        Logger.error("X-Ray SamplingTargets request failed, retrying in 10 seconds: #{inspect(error)}")
        {:error, error}
      {:ok, result} ->
        Logger.debug("received response: #{inspect(result)}")
        {:ok, result}
    end
  end

  defp xray_daemon_config() do
    %{scheme: "http://",
      host: List.to_string(:inet.ntoa(AwsExRay.Config.daemon_address())),
      port: AwsExRay.Config.daemon_port(),
      # no authentication needed for local daemon
      access_key_id: "",
      secret_access_key: ""}
  end
end
