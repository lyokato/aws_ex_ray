defmodule AwsExRay.Plug do

  alias AwsExRay.Context
  alias AwsExRay.Trace

  def init(options), do: options

  def call(conn, opts) do

    ctx = get_trace_context(conn)

    Process.put(:__aws_ex_ray__, ctx)

    seg = Context.start_segment(ctx)

    Plug.Conn.register_before_send(conn, fn conn ->

      Context.finish_segment(ctx, seg)
      Process.put(:__aws_ex_ray__, nil)

      conn

    end)
  end

  defp get_trace_context(conn) do
    with {:ok, value} <- find_trace_header(conn),
         {:ok, trace} <- Trace.Formatter.parse_http_header(value) do

      {:ok, trace}

    else
      {:error, :not_found} -> {:ok, Trace.new()}
    end
  end

  defp find_trace_header(conn) do
    headers = Plug.Conn.get_req_header(conn, "x-amzn-trace-id")
    if length(headers) > 0 do
      {:ok, List.first(headers)}
    else
      {:error, :not_found}
    end
  end

end
