use Mix.Config

config :aws_ex_ray, :client_module,
  AwsExRay.Client.Sandbox

config :aws_ex_ray, :sandbox_sink_module,
  AwsExRay.Client.Sandbox.Sink.Stub

config :aws_ex_ray, :sampling_rate, 1.0
