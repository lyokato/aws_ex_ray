defmodule AwsExRay.Test.MockedSink do

  @moduledoc false

  def start_agent() do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    setup_on_process(agent)
    agent
  end

  def setup_on_process(agent) do
    AwsExRay.Client.Sandbox.Sink.Stub
    |> Mox.stub(:send, fn data ->
      Agent.update(agent, fn state -> [data|state] end)
    end)
  end

  def get(agent) do
    Agent.get(agent, &(&1))
  end
end
