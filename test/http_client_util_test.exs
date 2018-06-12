defmodule AwsExRay.Test.HTTPClientUtilTest do

  use ExUnit.Case, async: true

  use StructAssert

  alias AwsExRay.Trace
  alias AwsExRay.Subsegment
  alias AwsExRay.Stacktrace
  alias AwsExRay.HTTPClientUtil

  setup do
    AwsExRay.Test.Mox.setup_default()
    :ok
  end

  test "response error 500" do
    sub = Subsegment.new(Trace.new(), "sub", :remote)
    sub = HTTPClientUtil.put_response_error(sub, 500, Stacktrace.stacktrace())
    data = sub |> Subsegment.to_json() |> Poison.decode!()
    assert data["throttle"] == false
    assert data["fault"] == true
    assert data["error"] == false
  end

  test "response error 429" do
    sub = Subsegment.new(Trace.new(), "sub", :remote)
    sub = HTTPClientUtil.put_response_error(sub, 429, Stacktrace.stacktrace())
    data = sub |> Subsegment.to_json() |> Poison.decode!()
    assert data["throttle"] == true
    assert data["fault"] == false
    assert data["error"] == true
  end

  test "response error 401" do
    sub = Subsegment.new(Trace.new(), "sub", :remote)
    sub = HTTPClientUtil.put_response_error(sub, 401, Stacktrace.stacktrace())
    data = sub |> Subsegment.to_json() |> Poison.decode!()
    assert data["throttle"] == false
    assert data["fault"] == false
    assert data["error"] == true
  end

end
