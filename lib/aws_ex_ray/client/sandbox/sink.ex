defmodule AwsExRay.Client.Sandbox.Sink do

  @moduledoc nil

  defmodule Behaviour do
    @moduledoc nil
    @callback send(data :: binary) :: term
  end

  defmodule Ignore do
    @moduledoc nil
    @behaviour AwsExRay.Client.Sandbox.Sink.Behaviour
    def send(_data) do
      # do nothing
      :ok
    end
  end

end
