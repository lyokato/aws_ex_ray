defmodule AwsExRay.Test.HTTPoisonTest do

  use ExUnit.Case

  import Mox

  setup do
    AwsExRay.Test.Mox.setup_default()
    :ok
  end

  test "httpoison subsegment" do

    {:ok, agent} = Agent.start_link(fn -> [] end)

    AwsExRay.Client.Sandbox.Sink.Stub
    |> stub(:send, fn data ->

      Agent.update(agent, fn state -> [data|state] end)

    end)

    trace = AwsExRay.Trace.new()
    segment = AwsExRay.start_tracing(trace, "dummy_trace_name")

    result = AwsExRay.HTTPoison.get! "http://httparrot.herokuapp.com/get"

    AwsExRay.finish_tracing(segment)

    #assert result == {:ok, ""}

    got = Agent.get(agent, &(&1))
    # TODO
    assert got == []

  end

end
