defmodule AwsExRay.Application do

  @moduledoc """
  Application module which starts aws_ex_ray's root supervisor
  """

  use Application

  @impl Application
  def start(_type, _args) do

    AwsExRay.Store.Table.init()

    children = [
      {AwsExRay.Client, []},
      {AwsExRay.Store.MonitorSupervisor, []}
    ]

    opts = [
      strategy: :one_for_one,
      name:     AwsExRay.Supervisor
    ]

    Supervisor.start_link(children, opts)

  end

end
