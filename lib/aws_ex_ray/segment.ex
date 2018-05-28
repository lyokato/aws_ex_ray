  defmodule AwsExRay.Segment do

    alias AwsExRay.Config

    defstruct name:       "",
              id:         "",
              trace_id:   "",
              version:    "",
              parent_id:  "",
              annotation: %{},
              metadata:   %{},
              start_time: 0,
              end_time:   0

    def build(name, trace_id) do
      build(name, trace_id, "")
    end
    def build(name, trace_id, parent_id) do
      %__MODULE__{
        id:         generate_id(),
        name:       name,
        version:    Config.service_version(),
        trace_id:   trace_id,
        parent_id:  parent_id,
        start_time: now(),
        end_time: 0,
        #annotation: %{
        #  hostname: "",
        #}
        metadata: %{
          tracing_sdk: %{
            name:    Config.library_name,
            version: Config.library_version,
          }
        }
      }
    end

    defp now() do
      System.system_time(:micro_seconds) / 1_000_000
    end

    defp generate_id() do
      SecureRandom.hex(8)
    end

    def finished?(seg) do
      seg.end_time > 0
    end

    def finish(seg) do
      %{seg|end_time: now()}
    end

    def to_json(seg) do

      embed_version = fn m ->
        if seg.version != "" do
          put_in(m.service.version, seg.version)
        else
          m
        end
      end

      embed_progress = fn m ->
        if finished?(seg) do
          put_in(m.in_progress, true)
        else
          put_in(m.end_time, seg.end_time)
        end
      end

      # TODO embed error

      %{
        name:        seg.name,
        id:          seg.id,
        trace_id:    seg.trace_id,
        start_time:  seg.start_time,
        #annotations: seg.annotations,
        metadata:    seg.metadata
      }
      |> embed_version.()
      |> embed_progress.()
      |> Poison.encode!()
    end

  end
