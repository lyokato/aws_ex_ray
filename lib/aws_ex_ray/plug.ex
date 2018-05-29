defmodule AwsExRay.Plug do

  import Plug.Conn

  alias AwsExRay.Plug.Paths
  alias AwsExRay.Trace

  @type http_method :: :get | :post | :put | :delete

  @type t :: %__MODULE__{
    name: String.t,
    skip: [{http_method, String.t}]
  }

  defstruct name: "", skip: []

  def init(opts \\ []) do

    name = Keyword.fetch!(opts, :name)
    skip = Keyword.get(opts, :skip, [])

    %__MODULE__{
      name: name,
      skip: skip
    }

  end

  def call(conn, opts) do

    if !can_skip_tracing(conn, opts) do

      trace = get_trace(conn)

      segment = AwsExRay.start_tracing(trace, opts.name)

      register_before_send(conn, fn conn ->

        AwsExRay.finish_tracing(segment)

        conn

      end)

    end

  end

  defp can_skip_tracing(conn, opts) do
    Paths.include(opts.skip, conn)
  end

  defp get_trace(conn) do
    with {:ok, value} <- find_trace_header(conn),
         {:ok, trace} <- Trace.Formatter.parse_http_header(value) do
      trace
    else
      {:error, :not_found} -> Trace.new()
    end
  end

  defp find_trace_header(conn) do
    headers = get_req_header(conn, "x-amzn-trace-id")
    if length(headers) > 0 do
      {:ok, List.first(headers)}
    else
      {:error, :not_found}
    end
  end

end
