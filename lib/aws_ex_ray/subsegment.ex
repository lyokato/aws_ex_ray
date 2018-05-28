  defmodule AwsExRay.Subsegment do

    defstruct name: "",
              trace_id: "",
              parent_id: "",
              remote: false

    def build(name, trace_id, parent_id, remote) do
      %__MODULE__{
        name:      name,
        trace_id:  trace_id,
        parent_id: parent_id,
        remote:    remote
      }
    end

  end
