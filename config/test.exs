use Mix.Config

config :aws_ex_ray,
  sampling_rate: 1.0,
  client_module: AwsExRay.Client.Sandbox,
  sandbox_sink_module: AwsExRay.Client.Sandbox.Sink.Stub,
  default_annotation: %{foo: "bar"},
  default_metadata: %{bar: "buz"}

