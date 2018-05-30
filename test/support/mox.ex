Mox.defmock(AwsExRay.Client.Sandbox.Sink.Stub, for: AwsExRay.Client.Sandbox.Sink.Behaviour)

defmodule AwsExRay.Test.Mox do

  import Mox

  def setup_default() do
    alias AwsExRay.Client.Sandbox.Sink
    Sink.Stub |> stub(:send, &Sink.Ignore.send/1)
  end

end
