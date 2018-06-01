# AwsExRay

## NOT STABLE YES

Please wait version 1.0.0 released.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `aws_ex_ray` to your list of dependencies in `mix.exs`:

```elixir
def application do
  [
    extra_applications: [
      :logger,
      :aws_ex_ray
      # ...
    ],
    mod {MyApp.Supervisor, []}
  ]
end

def deps do
  [
    {:aws_ex_ray, "~> 0.1.0"},

    # add support libraries as you like
    {:aws_ex_ray_plug, "~> 0.1.0"},
    {:aws_ex_ray_ecto, "~> 0.1.0"},
    {:aws_ex_ray_httpoison, "~> 0.1.0"},
    {:aws_ex_ray_ex_aws, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/aws_ex_ray](https://hexdocs.pm/aws_ex_ray).

## Plug Support

https://github.com/lyokato/aws_ex_ray_plug

In your router, set `AwsExRay.Plug`.

```elixir
defmodule MyPlugRouter do

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
```

## Ecto Support

https://github.com/lyokato/aws_ex_ray_ecto

In your config file,
put `AwsExRay.Ecto.Logger` into Ecto's `:loggers` setting.

```elixir
config :my_app, MyApp.EctoRepo,
  adapter: Ecto.Adapters.MySQL,
  hostname: "example.org",
  port:     "3306",
  database: "my_db",
  username: "foo",
  password: "bar",
  loggers:  [Ecto.LogEntry, AwsExRay.Ecto.Logger]
```

## HTTPoison Support

https://github.com/lyokato/aws_ex_ray_httpoison

use `AwsExRay.HTTPoison` instead of `HTTPoison`

```elixir
result = AwsExRay.HTTPoison.get! "http://httparrot.herokuapp.com/get"
```

## ExAws Support

https://github.com/lyokato/aws_ex_ray_ex_aws

In your config file,
put `AwsExRay.ExAws.HTTPClient` to `:http_client` setting.

```elixir
config :ex_aws,
  http_client: AwxExRay.ExAws.HTTPClient
```

