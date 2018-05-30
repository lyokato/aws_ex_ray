use Mix.Config

config :aws_ex_ray, :client_module,
  AwsExRay.Client.Sandbox

config :aws_ex_ray, :client_sink_module,
  AwsExRay.Client.Sandbox.Sink.Stub
