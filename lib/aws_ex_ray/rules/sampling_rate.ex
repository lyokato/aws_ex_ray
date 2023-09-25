defmodule AwsExRay.Rules.SamplingRate do

  @moduledoc """
  Use a flat sampling rate instead of sampling rules retrieved from AWS X-Ray.

  The sampling rate is taking from the :sampling_rate environment variable
  for the :aws_ex_ray application. If not specified, the default rate is
  0.1 (i.e. 10%).
  """

  @behaviour AwsExRay.Rules.Client.Behaviour

  @impl true
  def get_sampling_rules() do
    sampling_rate = AwsExRay.Config.sampling_rate()
    {:ok, [%{"SamplingRule" =>
              %{"Version" => 1,
                "Priority" => 0,
                "ReservoirSize" => 0,
                "FixedRate" => sampling_rate,
                "ServiceName" => "*",
                "ServiceType" => "*",
                "HTTPMethod" => "*",
                "Host" => "*",
                "URLPath" => "*",
                "ResourceARN" => "*"}}]}
  end

  @impl true
  def post_statistics(_statistics) do
    {:ok, %{"LastRuleModification" => 0,
            "SamplingTargetDocuments" => [%{"Interval" => 1_000_000}]}}
  end
end
