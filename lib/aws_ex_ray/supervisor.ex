defmodule AwsExRay.Supervisor do

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    children(opts)
    |> Supervisor.init(strategy: :one_for_one)
  end

  def children(_opts) do
    {AwxExRay.Client, []}
  end

end
