defmodule AwsExRay.Trace do

  alias AwsExRay.Config

  defstruct trace_id:       "",
            sampled:        true,
            parent_segment: ""

  @spec new() :: %__MODULE__{}
  def new() do
    %__MODULE__{
      trace_id:       generate_id(),
      sampled:        sample?(),
      parent_segment: nil,
    }
  end

  defp generate_id() do
    t = System.system_time(:seconds) |> Integer.to_string(16)
    "1-#{t}-#{SecureRandom.hex(12)}"
  end

  defp sample?() do
    :rand.uniform() > Config.sampling_rate
  end

end
