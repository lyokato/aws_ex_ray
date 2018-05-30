defmodule AwsExRay.Application do

  use Application

  def start(_type, _args) do

    children = [
      {AwsExRay.Client, []}
    ]

    opts = [
      strategy: :one_for_one,
      name:     AwsExRay.Supervisor
    ]

    Supervisor.start_link(children, opts)

  end

end
