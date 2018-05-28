defmodule AwsExRay.Client do

  alias AwsExRay.Config

  def child_spec(opts) do
    Config.client_module.child_spec(opts)
  end

  def send(data) do
    Config.client_module.send(data)
  end

end
