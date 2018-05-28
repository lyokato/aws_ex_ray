defmodule AwsExRay do

  def child_spec(opts) do
    AwsExRay.Supervisor.child_spec(opts)
  end

end
