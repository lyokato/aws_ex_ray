defmodule AwsExRay.NullClient do

  use GenServer

  def send(_data) do
    # do nothing
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, []}
  end

end
