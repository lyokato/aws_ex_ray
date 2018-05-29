defmodule AwsExRay.Plug do

  import Plug.Conn

  alias AwsExRay.Context
  alias AwsExRay.Trace

  def init(opts), do: opts

  def call(conn, _opts) do

    ctx = get_trace_context(conn)

    Process.put(:__aws_ex_ray__, ctx)

    seg = Context.start_segment(ctx, "plug")

    register_before_send(conn, fn conn ->

      Context.finish_segment(ctx, seg)
      Process.put(:__aws_ex_ray__, nil)

      conn

    end)

  end

  defp get_trace_context(conn) do
    find_trace(conn) |> AwsExRay.Context.new()
  end

  defp find_trace(conn) do
    with {:ok, value} <- find_trace_header(conn),
         {:ok, trace} <- Trace.Formatter.parse_http_header(value) do
      {:ok, trace}
    else
      {:error, :not_found} -> {:ok, Trace.new()}
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
