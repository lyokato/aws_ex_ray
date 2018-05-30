defmodule AwsExRay.Test.Router do

  use Plug.Router

  plug AwsExRay.Plug, name: "my-xray", skip: [{:get, "/bar"}]

  plug :match
  plug :dispatch

  get "/foo" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{body: "Hello, Foo"}))
  end

  get "/bar" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{body: "Hello, Bar"}))
  end

end
