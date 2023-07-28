defmodule AwsExRay.Rules do

  @moduledoc """
  Request sampling rules from and submit statistics to AWS X-Ray
  """

  use GenServer
  require Logger

  @rules_key {__MODULE__, :rules}
  @client_id_key {__MODULE__, :client_id}

  @doc """
  Get the current sample rules.
  """
  def get() do
    :persistent_term.get(@rules_key, [])
  end

  def sample?(%{}, []) do
    # We've gone through all the rules, and none matches
    false
  end
  def sample?(%{} = request, [rule | rules]) do
    fields = [:service_name,
              :service_type,
              :http_method,
              :host,
              :url_path,
              :resource_arn]
    case Enum.all?(fields, fn(field) -> wildcard_match?(request[field], rule[field]) end) do
      false ->
        sample?(request, rules)
      true ->
        # This is the lowest-priority rule that matches.
        # Should we sample?
        system_time = :os.system_time(:second)
        monotonic_time = System.monotonic_time(:second)
        rule_sample?(rule, system_time, monotonic_time)
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl true
  def init(_) do
    :persistent_term.put(@rules_key, [])
    :persistent_term.put(@client_id_key, generate_client_id())
    timer = Process.send_after(self(), :request_rules, 0)
    {:ok, %{
        last_rule_modification: 0,
        request_rules_timer: timer,
        post_statistics_timer: nil}}
  end

  @impl true
  def handle_info(:request_rules, state) do
    new_state = request_rules(state)
    {:noreply, new_state}
  end
  def handle_info(:post_statistics, state) do
    new_state = post_statistics(state)
    {:noreply, new_state}
  end

  defp request_rules(state) do
    case AwsExRay.Rules.Client.get_sampling_rules() do
      {:error, _error} ->
        maybe_cancel_timer(state.request_rules_timer)
        new_timer = Process.send_after(self(), :request_rules, 60_000)
        %{state | request_rules_timer: new_timer}
      {:ok, rule_records} ->
        :persistent_term.put(@rules_key, parse_rules(rule_records))
        maybe_cancel_timer(state.post_statistics_timer)
        new_timer = Process.send_after(self(), :post_statistics, 10_000)
        %{state |
          last_rule_modification: get_last_rule_modification(rule_records),
          post_statistics_timer: new_timer}
    end
  end

  defp parse_rules(rules) do
    rules
    # exclude rule versions we don't understand
    |> Enum.filter(& &1["SamplingRule"]["Version"] == 1)
    # lowest priority number goes _first_
    |> Enum.sort_by(& &1["SamplingRule"]["Priority"])
    |> Enum.map(&parse_rule/1)
  end

  defp parse_rule(rule) do
    # Create five atomic variables:
    # - reservoir quota
    # - reservoir quota TTL (seconds since Unix epoch),
    # - reservoir size
    # - reservoir last used timestamp (Erlang monotonic time in seconds),
    # - fixed sample rate (between 0 and one million)
    reservoir_variables = :atomics.new(5, signed: true)
    # The reservoir size is the total for all clients, so we can't use it directly.
    # However, if it is non-zero, we're allowed to "borrow" one sample per second.
    # Let's represent that by setting the quota to -1.
    reservoir_quota = case rule["SamplingRule"]["ReservoirSize"] do
                         0 -> 0
                        _non_zero -> -1
                      end
    :atomics.put(reservoir_variables, 1, reservoir_quota)
    :atomics.put(reservoir_variables, 4, System.monotonic_time(:second) - 1)
    :atomics.put(reservoir_variables, 5, round(rule["SamplingRule"]["FixedRate"] * 1_000_000))
    %{rule_arn: rule["SamplingRule"]["RuleARN"],
      rule_name: rule["SamplingRule"]["RuleName"],

      service_name: parse_wildcard(rule["SamplingRule"]["ServiceName"]),
      service_type: parse_wildcard(rule["SamplingRule"]["ServiceType"]),
      http_method: parse_wildcard(rule["SamplingRule"]["HTTPMethod"]),
      host: parse_wildcard(rule["SamplingRule"]["Host"]),
      url_path: parse_wildcard(rule["SamplingRule"]["URLPath"]),
      resource_arn: parse_wildcard(rule["SamplingRule"]["ResourceARN"]),

      reservoir_variables: reservoir_variables,
      # borrow count, sample count, request count
      counters: :counters.new(3, [:write_concurrency])
    }
  end

  defp parse_wildcard("*") do
    :wildcard
  end
  defp parse_wildcard(string) when is_binary(string) do
    if String.contains?(string, ["*", "?"]) do
      # Let's translate this wildcard-containing string to a regular expression
      regex = for <<c::utf8 <- string>>, into: "" do
        case c do
          ?* ->
            ".*"
          ?? ->
            "."
          _ ->
            Regex.escape(<<c::utf8>>)
        end
      end
      {:ok, compiled} = Regex.compile("^" <> regex <> "$")
      {:regex, compiled}
    else
      {:literal, string}
    end
  end

  defp get_last_rule_modification(rule_records) do
    rule_records
    |> Enum.map(fn(sampling_rule_record) ->
      # The documentation states that these timestamps are both optional,
      # so let's default to zero
      max(
        sampling_rule_record["CreatedAt"] || 0,
        sampling_rule_record["ModifiedAt"] || 0)
    end)
    # If there are no rules, default to zero
    |> Enum.max(&>=/2, fn -> 0 end)
  end

  defp wildcard_match?(_, :wildcard), do: true
  defp wildcard_match?(nil, _) do
    # If the value is missing, it matches a wildcard rule,
    # but nothing else.
    false
  end
  defp wildcard_match?(value, {:literal, pattern}), do: value == pattern
  defp wildcard_match?(value, {:regex, regex}), do: Regex.match?(regex, value)

  defp rule_sample?(rule, system_time, monotonic_time) do
    maybe_update_reservoir(rule, system_time, monotonic_time)
    # Increment request counter
    :counters.add(rule.counters, 3, 1)
    # First try using the per-second "reservoir"
    if :atomics.sub_get(rule.reservoir_variables, 3, 1) >= 0 do
      # Yes, we're using the reservoir.
      # Was it a "borrow"?
      if :atomics.get(rule.reservoir_variables, 1) == -1 do
        # Increment borrow counter
        :counters.add(rule.counters, 1, 1)
      end
      # Increment sample counter
      :counters.add(rule.counters, 2, 1)
      true
    else
      # Let's use the fixed rate.
      fixed_rate = :atomics.get(rule.reservoir_variables, 5)
      if fixed_rate > 0 and :rand.uniform(1_000_000) <= fixed_rate do
        # Yes, let's sample. Increment sample counter
        :counters.add(rule.counters, 2, 1)
        true
      else
        false
      end
    end
  end

  defp maybe_update_reservoir(%{reservoir_variables: reservoir_vars}, system_time, monotonic_time) do
    # The reservoir capacity resets every second.
    # Let's compare the "last used" timestamp to the current time,
    # and reset the reservoir if it's different.
    current_last_used = :atomics.get(reservoir_vars, 4)
    if current_last_used < monotonic_time and
        # Use compare_exchange to ensure that we're the only process
        # that resets the reservoir for this second.
        :atomics.compare_exchange(reservoir_vars, 4, current_last_used, monotonic_time) == :ok do
      reservoir_quota = :atomics.get(reservoir_vars, 1)
      reservoir_ttl = :atomics.get(reservoir_vars, 2)
      new_reservoir_size = cond do
        reservoir_quota > 0 and reservoir_ttl > 0 and reservoir_ttl < system_time ->
          # Our quota has expired. Let's revert to "borrowing".
          :atomics.put(reservoir_vars, 1, -1)
          1
        reservoir_quota == -1 ->
          # We don't have a quota, so we're "borrowing" one sample per second.
          1
        true ->
          # We have a quota, so use it.
          reservoir_quota
      end
      :atomics.put(reservoir_vars, 3, new_reservoir_size)
    end
  end

  defp generate_client_id() do
    # A client id is a 24 character long string containing a hexadecimal number.
    number = :rand.uniform(Bitwise.bsl(1, 96) - 1)
    List.to_string(:io_lib.format("~24.16.0B", [number]))
  end

  defp post_statistics(state) do
    rules = :persistent_term.get(@rules_key)
    statistics = rules |> Enum.map(&rule_statistics/1) |> Enum.filter(& &1)
    case AwsExRay.Rules.Client.post_statistics(statistics) do
      {:error, _error} ->
        maybe_cancel_timer(state.post_statistics_timer)
        new_timer = Process.send_after(self(), :post_statistics, 10_000)
        %{state | post_statistics_timer: new_timer}
      {:ok, result} ->
        handle_sampling_targets_result(result, state)
    end
  end

  defp handle_sampling_targets_result(result, state) do
    if result["LastRuleModification"] > state.last_rule_modification do
      Process.send_after(self(), :request_rules, 0)
    end
    case result["UnprocessedStatistics"] do
      unprocessed when unprocessed not in [nil, []] ->
        Logger.error("X-Ray SamplingTargets response reported unprocessed statistics: #{inspect(unprocessed)}")
      _ ->
        :ok
    end
    sampling_target_documents = result["SamplingTargetDocuments"]
    update_sampling_targets(sampling_target_documents)
    # Each sampling target has its own interval. Let's just pick the largest interval,
    # falling back to 10 seconds if there are no results.
    new_interval = Enum.max(
      Enum.map(sampling_target_documents,
        fn(entry) -> 1_000 * (Map.get(entry, "Interval") || 0) end),
      &>=/2,
      fn -> 10_000 end)
    Process.send_after(self(), :post_statistics, new_interval)
    state
  end

  defp rule_statistics(%{rule_name: rule_name, counters: counters}) do
    borrow_count = :counters.get(counters, 1)
    sampled_count = :counters.get(counters, 2)
    request_count = :counters.get(counters, 3)
    :counters.sub(counters, 1, borrow_count)
    :counters.sub(counters, 2, sampled_count)
    :counters.sub(counters, 3, request_count)
    case request_count do
      0 ->
        # nothing to report
        nil
      _ ->
        %{"ClientID" => :persistent_term.get(@client_id_key),
          "RuleName" => rule_name,
          "RequestCount" => request_count,
          "BorrowCount" => borrow_count,
          "SampledCount" => sampled_count,
          "Timestamp" => :os.system_time(:second) #DateTime.to_iso8601(DateTime.now!("Etc/UTC"))
         }
    end
  end

  defp update_sampling_targets(sampling_target_documents) do
    rules = :persistent_term.get(@rules_key)
    Enum.each(sampling_target_documents, &update_sampling_target(&1, rules))
  end

  defp update_sampling_target(
    %{"RuleName" => rule_name,
      "FixedRate" => fixed_rate,
      "ReservoirQuota" => reservoir_quota,
      "ReservoirQuotaTTL" => reservoir_quota_ttl},
    rules) do
    case Enum.find(rules, fn(%{rule_name: rn}) -> rn == rule_name end) do
      nil ->
        Logger.error("X-Ray SamplingTargets response contained unknown rule '#{rule_name}'")
      %{reservoir_variables: reservoir_vars} ->
        is_number(reservoir_quota) && :atomics.put(reservoir_vars, 1, reservoir_quota)
        is_number(reservoir_quota_ttl) && :atomics.put(reservoir_vars, 2, trunc(reservoir_quota_ttl))
        :atomics.put(reservoir_vars, 5, round(fixed_rate * 1_000_000))
    end
  end
  defp update_sampling_target(%{}, _rules) do
    # All the fields in the SamplingTargetDocument are optional.
    # Let's ignore entries without the fields we expect.
    nil
  end

  defp maybe_cancel_timer(nil) do
    nil
  end
  defp maybe_cancel_timer(timer) when is_reference(timer) do
    Process.cancel_timer(timer)
  end

  @doc """
  Return the current sample rules as a human-readable string.
  """
  def to_string() do
    get()
    |> Enum.map_join("\n", fn %{
                                rule_arn: rule_arn,
                                rule_name: rule_name,
                                reservoir_variables: reservoir_variables,
                                counters: counters
                              } = rule ->
      match_fields = [:service_name, :service_type, :http_method, :host, :url_path, :resource_arn]

      matches =
        rule
        |> Map.take(match_fields)
        |> Enum.reject(fn {_key, match} -> match == :wildcard end)
        |> case do
          [] ->
            "Matches anything"

          match_entries ->
            "Matches: " <>
              Enum.map_join(match_entries, ", ", fn
                {key, {:literal, literal}} ->
                  "#{key} = \"#{literal}\""

                {key, {:regex, regex}} ->
                  "#{key} ~= /#{Regex.source(regex)}/"
              end)
        end

      reservoir_quota = :atomics.get(reservoir_variables, 1)

      reservoir_quota_ttl =
        :atomics.get(reservoir_variables, 2) |> DateTime.from_unix!() |> DateTime.to_iso8601()

      reservoir_size = :atomics.get(reservoir_variables, 3)

      reservoir_last_used =
        (:atomics.get(reservoir_variables, 4) + System.time_offset(:second))
        |> DateTime.from_unix!()
        |> DateTime.to_iso8601()

      fixed_sample_rate = :atomics.get(reservoir_variables, 5)

      """
      Rule name: "#{rule_name}" ARN: #{rule_arn}
      #{matches}
      Borrow count: #{:counters.get(counters, 1)} Sampled count: #{:counters.get(counters, 2)} Request count: #{:counters.get(counters, 3)}
      Reservoir quota: #{reservoir_quota} Reservoir quota TTL: #{reservoir_quota_ttl}
      Reservoir size: #{reservoir_size} Reservoir last used: #{reservoir_last_used}
      Fixed sample rate (per million): #{fixed_sample_rate}
      """
    end)
  end
end
