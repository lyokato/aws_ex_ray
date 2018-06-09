defmodule AwsExRay do

  @moduledoc ~S"""

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
  If (2) server is HTTP server. You can put *X-Amzn-Trace-Id* into your requests HTTP headers.

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

  ## More Simple Inteface

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


  """

  require Logger

  alias AwsExRay.Client
  alias AwsExRay.Segment
  alias AwsExRay.Store
  alias AwsExRay.Subsegment
  alias AwsExRay.Trace
  alias AwsExRay.Util

  @spec start_tracing(
    trace :: Trace.t,
    name  :: String.t
  ) :: Segment.t

  def start_tracing(trace, name) do

    case Store.Table.lookup() do

      {:error, :not_found} ->
        segment = Segment.new(trace, name)
        Store.Table.insert(trace, segment.id)
        Store.MonitorSupervisor.start_monitoring(self())
        segment

      {:ok, _, _, _} ->
        raise "<AwsExRay> Tracing Context already exists on this process."

    end

  end

  @spec finish_tracing(segment :: Segment.t) :: :ok

  def finish_tracing(segment) do

    segment = segment
           |> Segment.finish()

    if Segment.sampled?(segment) do

      segment
      |> Segment.to_json()
      |> Client.send()

    end

    Store.Table.delete()

    :ok

  end

  @spec trace(
    trace       :: Trace.t,
    name        :: String.t,
    annotations :: map,
    func        :: fun
  ) :: any
  def trace(trace, name, annotations, func) do
    segment = start_tracing(trace, name)
    segment = annotations
            |> Enum.reduce(segment, fn {key, value}, seg ->
              Segment.add_annotation(seg, key, value)
            end)
    try do
      func.()
    after
      finish_tracing(segment)
    end
  end

  @spec trace(
    trace :: Trace.t,
    name  :: String.t,
    func  :: fun
  ) :: any
  def trace(trace, name, func), do: trace(trace, name, %{}, func)

  @spec start_subsegment(
    name :: String.t,
    opts :: keyword
  ) :: {:ok, Subsegment.t}
    |  {:error, :out_of_xray}

  def start_subsegment(name, opts \\ []) do

    tracing_pid = Keyword.get(opts, :tracing_pid)
    {target_pid, update_table} =
      if tracing_pid == nil do
        {self(), true}
      else
        {tracing_pid, false}
      end

    ns = Keyword.get(opts, :namespace, :none)

    case Store.Table.lookup(target_pid) do

      {:ok, trace, segment_id, []} ->
        subsegment =
          setup_subsegment(trace, name, ns, segment_id, update_table)
        {:ok, subsegment}

      {:ok, trace, _segment_id, [current_id|_rest]} ->
        subsegment =
          setup_subsegment(trace, name, ns, current_id, update_table)
        {:ok, subsegment}

      {:error, :not_found} ->
        {:error, :out_of_xray}

    end
  end

  defp setup_subsegment(trace, name, ns, parent_id, update_table) do
    subsegment = %{trace|parent: parent_id}
               |> Subsegment.new(name, ns)

    if update_table do
      subsegment
      |> Subsegment.id()
      |> Store.Table.push_subsegment()
    end

    subsegment
  end

  @spec finish_subsegment(
    subsegment :: Subsegment.t,
    end_time   :: number
  ) :: :ok

  def finish_subsegment(subsegment, end_time \\ Util.now()) do

    subsegment = subsegment
               |> Subsegment.finish(end_time)

    if Subsegment.sampled?(subsegment) do

      subsegment
      |> Subsegment.to_json()
      |> Client.send()

    end

    subsegment
    |> Subsegment.id()
    |> Store.Table.pop_subsegment()

    :ok

  end

  @spec subsegment(
    name        :: String.t,
    annotations :: map,
    opts        :: keyword,
    func        :: fun
  ) :: :ok
  def subsegment(name, annotations, opts, func) do
    subsegment_state = start_subsegment(name, opts)
    try do
      func.()
    after
      case subsegment_state do
        {:ok, subsegment} ->
          subsegment = annotations
                     |> Enum.reduce(subsegment, fn {key, value}, seg ->
                       Subsegment.add_annotation(seg, key, value)
                     end)
          finish_subsegment(subsegment)
        {:error, :out_of_xray} ->
          :ok
      end
    end
  end

  @spec subsegment(
    name :: String.t,
    opts :: keyword,
    func :: fun
  ) :: :ok
  def subsegment(name, opts, func), do: subsegment(name, %{}, opts, func)

end
