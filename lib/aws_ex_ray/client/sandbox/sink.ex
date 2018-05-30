defmodule AwsExRay.Client.Sandbox.Sink do

  defmodule Behaviour do
    @callback send(data :: binary) :: term
  end

  defmodule Ignore do
    @behaviour AwsExRay.Client.Sandbox.Sink.Behaviour
    def send(_data) do
      # do nothing
      :ok
    end
  end

end
