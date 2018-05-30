#Mox.defmock(AwsExRay.Client.Sandbox, for: AwsExRay.Client.Behaviour)
#
defmodule AwsExRay.Test.Mox do
  import Mox

  def setup_default() do
    #AwsExRay.Clinet.Sandbox |> stub(:send, fn _data ->
    #  :ok
    #end)
  end

end
