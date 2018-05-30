Application.ensure_all_started(:mox)
AwsExRay.Client.Sandbox.start_link([])
ExUnit.start()
