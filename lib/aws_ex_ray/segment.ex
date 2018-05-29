  defmodule AwsExRay.Segment do

    alias AwsExRay.Config
    alias AwsExRay.Segment.Formatter
    alias AwsExRay.Util

    defstruct id:         "",
              name:       "",
              version:    "",
              trace:      nil,
              start_time: 0,
              end_time:   0,
              annotation: %{},
              metadata:   %{}

    def new(trace, name) do
      %__MODULE__{
        id:         Util.generate_model_id(),
        name:       name,
        version:    Config.service_version(),
        trace:      trace,
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
