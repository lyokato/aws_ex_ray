defmodule AwsExRay.ID do

  def new_trace_id() do
    "1-#{}-#{}"
  end

  def new_segment_id() do
    #random hex
  end

end
