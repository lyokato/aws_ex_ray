Mox.defmock(AwsExRay.Client.Sandbox.Sink.Stub, for: AwsExRay.Client.Sandbox.Sink.Behaviour)
Mox.defmock(AwsExRay.Rules.Client.Stub, for: AwsExRay.Rules.Client.Behaviour)

defmodule AwsExRay.Test.Mox do

  @moduledoc nil

  import Mox

  def setup_default() do
    alias AwsExRay.Client.Sandbox.Sink
    Sink.Stub |> stub(:send, &Sink.Ignore.send/1)
  end

end
