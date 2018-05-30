defmodule AwsExRay.Application do

  use Application

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
