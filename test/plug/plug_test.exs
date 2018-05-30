defmodule AwsExRay.Test.PlugTest do

  use ExUnit.Case
  use Plug.Test

  alias AwsExRay.Test.Router
  import Mox

  require Logger

  setup do
    AwsExRay.Test.Mox.setup_default()
    :ok
  end

  @opts Router.init([])

  test "plug" do

    {:ok, agent} = Agent.start_link(fn -> [] end)

    AwsExRay.Client.Sandbox.Sink.Stub
    |> stub(:send, fn data ->

      Logger.warn data
      Agent.update(agent, fn state -> [data|state] end)

    end)

    conn = conn(:get, "/foo")
         |> put_req_header("content-type", "application/json")

    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    resp = Poison.decode!(conn.resp_body)
    assert resp["body"] == "Hello, Foo"


    got = Agent.get(agent, &(&1))
    # TODO
    assert got == []

  end

end
