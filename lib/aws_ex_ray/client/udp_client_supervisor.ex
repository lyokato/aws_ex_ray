defmodule AwsExRay.Client.UDPClientSupervisor do

  use Supervisor

  alias AwsExRay.Config
  alias AwsExRay.Client.UDPClient

  @pool_name :aws_ex_ray_client_pool

  def send(data) do
    :poolboy.transaction(__MODULE__, fn client ->
      UDPClient.send(client, data)
    end)
  end

  def start_link(_args), do: start_link()
  def start_link() do
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

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
