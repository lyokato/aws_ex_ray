defmodule AwsExRay.Config do

  @default_sampling_rate        0.1
  @default_daemon_address       "127.0.0.1"
  @default_daemon_port          2000
  @default_client_pool_size     5
  @default_client_pool_overflow 0
  @default_client_module        AwsExRay.Client.UDPClientSupervisor

  def library_name() do
    "aws-ex-ray"
  end

  def library_version() do
    "0.0.1"
  end

  def get(key, default) do
    Application.get_env(:aws_ex_ray, key, default)
  end

  def sampling_rate() do
    get(:sampling_rate,
        @default_sampling_rate)
  end

  def daemon_address() do

    address = get(:daemon_address,
                  @default_daemon_address)

    {:ok, ip_address} =
      address |> String.to_charlist() |> :inet.parse_address()

    ip_address

  end

  def daemon_port() do
    get(:daemon_port,
        @default_daemon_port)
  end

  def client_pool_size() do
    get(:client_pool_size,
        @default_client_pool_size)
  end

  def client_pool_overflow() do
    get(:client_pool_overflow,
        @default_client_pool_overflow)
  end

  def client_module() do
    get(:client_module,
        @default_client_module)
  end

  def service_version() do
    get(:service_version, "")
  end

end
