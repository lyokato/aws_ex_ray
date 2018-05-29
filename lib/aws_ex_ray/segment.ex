  defmodule AwsExRay.Segment do

    alias AwsExRay.Config
    alias AwsExRay.Segment.Formatter
    alias AwsExRay.Util

    defstruct id:         "",
              name:       "",
              version:    "",
              trace_id:   "",
              parent_id:  "",
              start_time: 0,
              end_time:   0,
              annotation: %{},
              metadata:   %{}

    def build(name, trace_id, parent_id) do
      %__MODULE__{
        id:         generate_id(),
        name:       name,
        version:    Config.service_version(),
        trace_id:   trace_id,
        parent_id:  parent_id,
        # TODO start_time, end_timeを固定値でも作れるようにする
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
        }
      }
    end

    defp generate_id() do
      SecureRandom.hex(8)
    end

    def finished?(seg) do
      seg.end_time > 0
    end

    def finish(seg) do
      %{seg|end_time: Util.now()}
    end

    def to_json(seg), do: Formatter.to_json(seg)

  end
