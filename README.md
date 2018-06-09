# AwsExRay

## NOT STABLE YET

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
    {:aws_ex_ray, "~> 0.1"},

    # add support libraries as you like
    {:aws_ex_ray_plug, "~> 0.1"},
    {:aws_ex_ray_ecto, "~> 0.1"},
    {:aws_ex_ray_httpoison, "~> 0.1"},
    {:aws_ex_ray_ex_aws, "~> 0.1"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/aws_ex_ray](https://hexdocs.pm/aws_ex_ray).

## Preparation

Setup your AWS environment.

Run `xray` daemon on an EC2 instance which you want your application run on.

https://docs.aws.amazon.com/xray/latest/devguide/xray-daemon.html

## USAGE

```elixir
trace = Trace.new()
segment = AwsExRay.start_tracing(trace, "root_segment_name")
do_your_job()
AwsExRay.finish_tracing(segment)
```

```elixir
def do_your_job() do

  current_trace = AwsExRay.start_subsegment("subsegment-name")

  do_some_work()

  case current_trace do
    {:ok, subsegment} ->
      AwsExRay.finish_subsegment(subsegment)

    {:error, :out_of_xray} -> :ok # you need to do nothing.
  end

end
```


## Multi Processes

Following example doesn't work.
`start_subsegment` returns always `{:error, :out_of_xray}`.
Because the subsegment is not on the process which start tracing.

Pay attention when you use Task.Supervisor or GenServer.

```elixir
segment = AwsExRay.start_tracing(trace, "root_segment_name")

Task.Supervisor.start_child(MyTaskSupervisor, fn ->

  ####################################################################
  # this function is executed on different process as root-segment!!!
  ####################################################################

  current_trace = AwsExRay.start_subsegment("subsegment-name")

  do_some_work()

  case current_trace do
    {:ok, subsegment} ->
      AwsExRay.finish_subsegment(subsegment)

    {:error, :out_of_xray} -> :ok
  end

end)
```
The solution.

Call `AwsExRay.Process.keep_tracing(process_which_starts_tracing)` like following

```elixir
segment = AwsExRay.start_tracing(trace, "root_segment_name")

tracing_pid = self()

Task.Supervisor.start_child(MyTaskSupervisor, fn ->

  AwsExRay.Process.keep_tracing(tracing_pid)

  current_trace = AwsExRay.start_subsegment("subsegment-name")

  do_some_work()

  case current_trace do
    {:ok, subsegment} ->
      AwsExRay.finish_subsegment(subsegment)

    {:error, :out_of_xray} -> :ok
  end

end)
```

## Multi Servers

```
[client] --> [1: front_server] --> [2: internal_api or job_worker]
```

You can tracking **Trace** including (2) not only (1).
If (2) server is HTTP server. You can put **X-Amzn-Trace-Id** into your requests HTTP headers.

### calling internal api on (1)

If you use AwsExRay.HTTPoison, it's easy. all you have to do is to set `:traced` option.

```elixir
options = [traced: true]
result = AwsExRay.HTTPoison.get(url, headers, options)
```

### received internal request on (2)

If you setup AwsExRay.Plug, it automatically takes over tracing.

```elixir
defmodule MyInternalAPIRouter do

  use Plug.Router

  plug AwsExRay.Plug, name: "my-internal-api"
```

### WITHOUT SUPPORT LIBRARIES

You can directory pass **Trace** value

```elixir

case AwsExRay.start_subsegment("internal-api-request", namespace: :remote) do

  {:error, :out_of_xray} ->
    pass_job_in_some_way(%{
      your_job_data: ...
    })

  {:ok, subsegment} ->
    pass_job_in_some_way(%{
      your_job_data: ...
      trace_value: Subsegment.generate_trace_value(subsegment)
    })
    AwsExRay.finish_subsegment(subsegment)

end
```

And job worker side, it can take over the **Trace**

```elixir

job = receive_job_in_some_way()

case AwsExRay.Trace.parse(job.trace_value) do
  {:ok, trace}
    AwsExRay.start_tracing(trace, "internal-job-name")
    :ok

  {:error, :not_found} ->
    :ok
end
```

## More Simple Interface

If you don't need to put detailed parameters into segment/subsegment,
You can do like following

### Segment

```elixir
trace = Trace.new()
result = AwsExRay.trace(trace, "root_segment_name", fn ->
  do_your_job()
end)
```

This is same as,

```elixir
AwsExRay.finish_tracing(segment)
segment = AwsExRay.start_tracing(trace, "root_segment_name")
result = do_your_job()
AwsExRay.finish_tracing(segment)
result
```

This way supports just only `annotations`

```elixir
trace = Trace.new()
result = AwsExRay.trace(trace, "root_segment_name", %{"MyAnnotationKey" => "MyAnnotationValue"}, fn ->
  do_your_job()
end)
```

### Subsegment

```elixir
opts = [namespace: :none]
result = AwsExRay.subsegment("name", opts, fn ->
  do_your_job()
end)
```

This is same as,

```elixir
current_trace = AwsExRay.start_subsegment("subsegment-name")

result = do_some_work()

case current_trace do
  {:ok, subsegment} ->
    AwsExRay.finish_subsegment(subsegment)

  {:error, :out_of_xray} -> :ok # you need to do nothing.
end

result
```

This way supports just only `annotations`

```elixir
opts = [namespace: :none]
result = AwsExRay.subsegment("name", %{"MyAnnotationKey" => "MyAnnotationValue"}, opts, fn ->
  do_your_job()
end)
```

## Configuration

```elixir
config :aws_ex_ray,
  sampling_rate: 0.1,
  default_annotation: %{foo: "bar"},
  default_metadata: %{bar: "buz"}
```

|key|default|description|
|:--|:--|:--|
|sampling_rate|0.1|set number between 0.0 - 1.0. recommended that set 0.0 for 'test' environment|
|default_annotation|%{}|annotation parameters automatically put into segment/subsegment|
|default_metadata|%{}|metadata parameters automatically put into segment/subsegment|
|daemon_address|127.0.0.1|your xray daemon's IP address. typically, you don't need to customize this.|
|daemon_port|2000|your xray daemon's port. typically, you don't need to customize this.|
|default_client_pool_size|10|number of UDP client which connects to xray daemon|
|default_client_pool_overflow|100|overflow capacity size of UDP client|
|default_store_monitor_pool_size|10|number of tracing-process-monitor|

## Support Libraries

### Plug Support

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

Then automatically start tracing segment if the request is not included skip setting.

### Ecto Support

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

Then automatically record subsegment if queries called on the tracing process.

### HTTPoison Support

https://github.com/lyokato/aws_ex_ray_httpoison

use `AwsExRay.HTTPoison` instead of `HTTPoison`

```elixir
result = AwsExRay.HTTPoison.get! "https://example.org/"
```

Then automatically record subsegment if HTTP request called on the tracing process.

### ExAws Support

https://github.com/lyokato/aws_ex_ray_ex_aws

In your config file,
put `AwsExRay.ExAws.HTTPClient` to `:http_client` setting.

```elixir
config :ex_aws,
  http_client: AwxExRay.ExAws.HTTPClient
```

Then automatically record subsegment if HTTP request toward AWS-Services called on the tracing process.

## LICENSE

MIT-LICENSE

## Author

Lyo Kaot <lyo.kato __at__ gmail.com>
