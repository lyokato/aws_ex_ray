defmodule AwsExRay.Client.UDPClientSupervisor do

  @moduledoc ~S"""
  Supervise some UDP client (GenServer) for xray-daemon with poolboy.
  You con configure the number of pool-size and overflow. See also AwsExRay.Config.
  """

  use Supervisor

  alias AwsExRay.Config
  alias AwsExRay.Client.UDPClient

  @behaviour AwsExRay.Client.Behaviour

  @pool_name :aws_ex_ray_client_pool

  @impl AwsExRay.Client.Behaviour
  def send(data) do
    :poolboy.transaction(@pool_name, fn client ->
      UDPClient.send(client, data)
    end)
  end

  def start_link(_args), do: start_link()
  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [:poolboy.child_spec(
      @pool_name,
      pool_options(),
      client_options()
    )]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def client_options() do
    [
      address: Config.daemon_address,
      port:    Config.daemon_port
    ]
  end

  def pool_options() do
    [
      {:name, {:local, @pool_name}},
      {:worker_module, UDPClient},
      {:size, Config.client_pool_size},
      {:max_overflow, Config.client_pool_overflow}
    ]
  end


end
