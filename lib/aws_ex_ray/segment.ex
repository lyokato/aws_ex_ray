  defmodule AwsExRay.Segment do

    alias AwsExRay.Config
    alias AwsExRay.Segment.Formatter
    alias AwsExRay.Trace
    alias AwsExRay.Util

    @type t :: %__MODULE__{
      id:         String.t,
      name:       String.t,
      version:    String.t,
      trace:      Trace.t,
      start_time: number,
      end_time:   number,
      annotation: map,
      metadata:   map,
      http:       map
    }

    defstruct id:         "",
              name:       "",
              version:    "",
              trace:      nil,
              start_time: 0,
              end_time:   0,
              annotation: %{},
              metadata:   %{},
              http: %{}

    def new(trace, name) do
      %__MODULE__{
        id:         Util.generate_model_id(),
        name:       name,
        version:    Config.service_version(),
        trace:      trace,
        start_time: Util.now(),
        end_time:   0,
        annotation: %{
          # TODO how to set hostname? by AWS-CLI API?
          hostname: "",
        },
        metadata: %{
          tracing_sdk: %{
            name:    Config.library_name,
            version: Config.library_version,
          }
        },
        http: %{
          request: nil,
          response: nil
        }
      }
    end

    def set_http_request(seg, req) do
      put_in(seg.http.request, req)
    end

    def set_http_response(seg, res) do
      put_in(seg.http.response, res)
    end

    def sampled?(seg) do
      seg.trace.sampled
    end

    def finished?(seg) do
      seg.end_time > 0
    end

    def finish(seg) do
      if finished?(seg) do
        seg
      else
        %{seg|end_time: Util.now()}
      end
    end

    def to_json(seg), do: Formatter.to_json(seg)

  end
