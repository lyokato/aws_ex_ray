defmodule AwsExRay.Client do

  require Logger

  use GenServer

  @moduledoc """
  This is a UDP client module which reports TRACE information to a XRay daemon
  running on localhost.
  """

  #@daemon_version "1.2.3"

  @max_retry 10

  @header "{\"format\": \"json\", \"version\": 1}\n"

  defstruct address: nil,
            port:    2000,
            socket:  nil

  def send(data) do
    GenServer.call(__MODULE__, {:send, data})
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do

    address = Keyword.fetch!(opts, :address)
    port    = Keyword.fetch!(opts, :port)

    Process.flag(:trap_exit, true)

    case open(0, @max_retry) do

      {:ok, socket} ->
        state = %{
          address: address,
          port:    port,
          socket:  socket,
        }
        {:ok, state}

      :error -> {:stop, :daemon}

    end

  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    {:stop, :normal, state}
  end

  def handle_call({:send, data}, state) do
    case send_data(data, state) do
      :ok ->
        {:noreply, state}
      _other ->
        Logger.error "<AwsExRay.Client> failed to send data"
        {:stop, :normal, state}
    end
  end

  def terminate(_reason, state) do
    :gen_udp.close(state.socket)
    :ok
  end

  defp open(attempts, max_retry) do

    port = get_port()

    case :gen_udp.open(port, [:binary]) do

      {:ok, socket} -> {:ok, socket}

      other when attempts < max_retry ->
        Logger.error "<AwsExRay.Client> failed to open UDP(#{port}): #{inspect other}, retry"
        open(attempts + 1, max_retry)

      other ->
        Logger.error "<AwsExRay.Client> failed to open UDP(#{port}): #{inspect other}, shutdown"
        :error

    end
  end

  defp get_port() do
    :rand.uniform(65535 - 1023) + 1023
  end

  defp send_data(data, state) do
    :gen_udp.send(
      state.socket,
      state.address,
      state.port,
      pack_data(data)
    )
  end

  defp pack_data(data) do
    (@header <> data)
    |> String.to_charlist
    |> :erlang.term_to_binary
  end

end
