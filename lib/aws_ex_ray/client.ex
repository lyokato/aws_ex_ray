defmodule AwsExRay.Client do

  @moduledoc ~S"""
  This module is a facade interface to send report-data to
  xray-daemons running on your localhost.
  """

  defmodule Behaviour do
    @moduledoc ~S"""
    Real client requires IO, so to enable mocking
    on test environment, provides a interface and swithable modules.
    """
    @callback send(data :: binary) :: term
  end

  alias AwsExRay.Config

  @spec child_spec(any) :: Supervisor.child_spec
  def child_spec(opts) do
    Config.client_module.child_spec(opts)
  end

  @spec send(binary) :: :ok
  def send(data) do
    Config.client_module.send(data)
    :ok
  end

end
