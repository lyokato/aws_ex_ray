defmodule AwsExRay do

  @moduledoc """

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

    AwsExRay.finish_subsegment(subsegment)
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
    # this function is executed on different process as root-segemnet!!!
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

  Call `AwsExRay.Process.keep_tracing( process_which_starts_tracing)` like following

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
  If (2) server is HTTP server. You can put *X-Amzn-Trace-Id* into your requests HTTP headers.

  ### calling internal api on (1)

  If you use AwsExRay.HTTPoison, it's easy. all you have to do is to set `:traced` option.

  ```elixir
  options = [traced: true]
  result = AwsExRay.HTTPoison.get(url, headers, options)
  ```

  ### received internal request on (2)

  If you use AwsExRay.Plug, automatically continue tracing.

  ```elixir
  defmodule MyInternalAPIRouter do

    use Plug.Router

    plug AwsExRay.Plug, name: "my-internal-api"
  ```

  ### WITHOUT SUPPORT LIBRARIES

  You can directory pass **Trace** value

  ```elixir
  trace_value = #{segment.trace}

  pass_job_in_some_way(%{
    your_job_data: ...
    trace: trace_value
  })
  ```

  And job worker side, it can take over the **Trace**

  ```elixir

  job = receive_job_in_some_way()

  case AwsExRay.Trace.parse(job.trace) do
    {:ok, trace}
      AwsExRay.start_tracing(trace, "internal-job-name")
      :ok

    {:error, :not_found} ->
      :ok
  end
  ```

  """

  require Logger

  alias AwsExRay.Client
  alias AwsExRay.Segment
  alias AwsExRay.Store
  alias AwsExRay.Subsegment
  alias AwsExRay.Trace
  alias AwsExRay.Util

  @spec start_tracing(trace :: Trace.t, name :: String.t) :: Segment.t

  def start_tracing(trace, name) do

    segment = Segment.new(trace, name)

    Store.Table.insert(trace, segment.id)
    Store.MonitorSupervisor.start_monitoring(self())

    segment

  end

  @spec finish_tracing(segment :: Sugment.t) :: :ok

  def finish_tracing(segment) do

    segment = segment
           |> Segment.finish()

    if Segment.sampled?(segment) do

      segment
      |> Segment.to_json()
      |> Client.send()

    end

    :ok

  end

  @spec start_subsegment(name :: String.t, opts :: keywords)
    :: {:ok, subsegment}
     | {:error, :out_of_xray}
  def start_subsegment(name, opts \\ []) do

    ns  = Keyword.get(opts, :namespace, :none)
    pid = Keyword.get(opts, :tracing_pid, self())

    case Store.Table.lookup(pid) do

      {:ok, trace, segment_id} ->
        subsegment = %{trace|parent: segment_id}
                   |> Subsegment.new(name, ns)
        {:ok, subsegment}

      {:error, :not_found} ->
        {:error, :out_of_xray}

    end
  end

  @spec finish_subsegment(subsegment :: Subsegment.t, end_time :: number) :: :ok

  def finish_subsegment(subsegment, end_time \\ Util.now()) do

    subsegment = subsegment
               |> Subsegment.finish(end_time)

    if Subsegment.sampled?(subsegment) do

      subsegment
      |> Subsegment.to_json()
      |> Client.send()

    end

    :ok

  end

end
