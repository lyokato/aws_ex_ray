defmodule AwsExRay.Config do

  @moduledoc """

  ## Configuration

  ```elixir
  config :aws_ex_ray,
    sampling_rate: 0.1,
    default_annotation: %{foo: "bar"},
    default_metadata: %{bar: "buz"}
  ```

  |key|default|description|
  |:--|:--|:--|
  |sampling_rate|0.1|set number between 0.0 - 1.0. recommended that set 0.0 for 'test' environment|
  |default_annotation|%{}|annotation parameters automatically put into segment/subsegment|
  |default_metadata|%{}|metadata parameters automatically put into segment/subsegment|
  |daemon_address|127.0.0.1|your xray daemon's IP address. typically, you don't need to customize this.|
  |daemon_port|2000|your xray daemon's port. typically, you don't need to customize this.|
  |default_client_pool_size|10|number of UDP client which connects to xray daemon|
  |default_client_pool_overflow|100|overflow capacity size of UDP client|
  |default_store_monitor_pool_size|10|number of tracing-process-monitor|

  """

  @default_sampling_rate           0.1
  @default_daemon_address          "127.0.0.1"
  @default_daemon_port             2000
  @default_client_pool_size        10
  @default_client_pool_overflow    100
  @default_store_monitor_pool_size 10
  @default_client_module        AwsExRay.Client.UDPClientSupervisor
  @default_sandbox_sink_module  AwsExRay.Client.Sandbox.Sink.Ignore

  def library_name(), do: "aws-ex-ray"

  def library_version(), do: "0.0.1"

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

  def default_annotation() do
    get(:default_annotation, %{})
  end

  def default_metadata() do
    get(:default_metadata, %{})
  end

  def store_monitor_pool_size() do
    get(:store_monitor_pool_size,
        @default_store_monitor_pool_size)
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

  def sandbox_sink_module() do
    get(:sandbox_sink_module,
        @default_sandbox_sink_module)
  end

  def service_version() do
    get(:service_version, "")
  end

end
