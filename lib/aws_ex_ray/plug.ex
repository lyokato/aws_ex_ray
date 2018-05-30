defmodule AwsExRay.Plug do

  import Plug.Conn

  alias AwsExRay.Plug.Paths
  alias AwsExRay.Record.HTTPRequest
  alias AwsExRay.Record.HTTPResponse
  alias AwsExRay.Segment
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

      request_record = %HTTPRequest{
        segment_type: :segment,
        method:       conn.method,
        url:          request_url(conn),
        user_agent:   get_user_agent(conn),
      }
      # TODO
      #  client_ip,
      #  x_forwarded_for

      segment = AwsExRay.start_tracing(trace, opts.name)
              |> Segment.set_http_request(request_record)

      register_before_send(conn, fn conn ->

        content_length = get_response_content_length(conn)

        response_record =
          HTTPResponse.new(conn.status, content_length)

        segment =
          Segment.set_http_response(segment, response_record)

        # TODO set error into segment if needed

        AwsExRay.finish_tracing(segment)

        conn

      end)

    end

  end

  defp get_user_agent(conn) do
    case get_req_header(conn, "user-agent") do
      []        -> nil
      [value|_] -> value
    end
  end

  defp get_response_content_length(conn) do
    case get_resp_header(conn, "content-length") do
      []        -> 0
      [value|_] -> String.to_integer(value)
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
