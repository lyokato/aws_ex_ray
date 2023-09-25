defmodule AwsExRay.Rules.Client do

  @moduledoc ~S"""
  This module is a facade interface for getting sampling rules
  and reporting statistics.
  """

  defmodule Behaviour do
    # get_sampling_rules returns a list of SamplingRuleRecord JSON objects,
    # in map form
    @callback get_sampling_rules() :: {:ok, [map()]} | {:error, term()}
    # post_statistics takes a list of SamplingStatisticsDocument JSON objects,
    # in map form, and returns a response as from the GetSamplingTargets API call
    @callback post_statistics([map()]) :: {:ok, map()} | {:error, term()}
  end

  alias AwsExRay.Config

  @spec child_spec(any) :: Supervisor.child_spec
  def child_spec(opts) do
    Config.rules_module.child_spec(opts)
  end

  @spec get_sampling_rules() :: {:ok, [map()]} | {:error, term()}
  def get_sampling_rules() do
    Config.rules_module.get_sampling_rules()
  end

  @spec post_statistics([map()]) :: {:ok, map()} | {:error, term()}
  def post_statistics(statistics_documents) do
    Config.rules_module.post_statistics(statistics_documents)
  end
end
