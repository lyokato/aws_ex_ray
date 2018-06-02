defmodule AwsExRayTraceTest do
  use ExUnit.Case

  alias AwsExRay.Trace

  test "trace" do
    t = Trace.new()
    assert "#{t}" == "Root=#{t.root};Sampled=1"
  end
end
