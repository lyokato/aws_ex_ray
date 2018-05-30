defmodule AwsExRay.Client.Sandbox do

  use GenServer

  @sink_mod AwsExRay.Config.sandbox_sink_module

  def send(data) do
    @sink_mod.send(data)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, []}
  end

end
