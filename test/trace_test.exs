defmodule AwsExRay.Test.TraceTest do
  use ExUnit.Case, async: false

  alias AwsExRay.Trace

  test "trace format" do
    t = Trace.new()
    assert "#{t}" == "Root=#{t.root};Sampled=0"

    t = %{t|sampled: true}
    assert "#{t}" == "Root=#{t.root};Sampled=1"

    t = %{t|parent: "foobar"}
    assert "#{t}" == "Root=#{t.root};Parent=foobar;Sampled=1"

  end

  test "parsing trace value" do
    assert Trace.parse("") == {:error, :not_found}

    {:ok, t1} = Trace.parse("Root=hoge;Sampled=1")
    assert t1.root == "hoge"
    assert t1.sampled == true
    assert t1.parent == ""

    {:ok, t2} = Trace.parse("Root=hoge;Parent=foobar;Sampled=1")
    assert t2.root == "hoge"
    assert t2.sampled == true
    assert t2.parent == "foobar"

    {:ok, t3} = Trace.parse("Root=hoge;Parent=foobar;Sampled=0")
    assert t3.root == "hoge"
    assert t3.sampled == false
    assert t3.parent == "foobar"

    rate_backup = Application.get_env(:aws_ex_ray, :sampling_rate)
    Application.put_env(:aws_ex_ray, :sampling_rate, 1.0)

    {:ok, t4} = Trace.parse("Root=hoge")
    assert t4.root == "hoge"
    # Just parsing a trace value doesn't assign a sample flag
    assert t4.sampled == :undefined
    assert t4.parent == ""

    Application.put_env(:aws_ex_ray, :sampling_rate, 0.0)
    {:ok, t5} = Trace.parse("Root=hoge")
    assert t5.root == "hoge"
    # Likewise
    assert t5.sampled == :undefined
    assert t5.parent == ""

    Application.put_env(:aws_ex_ray, :sampling_rate, rate_backup)

    assert Trace.parse("Parent=foobar;Sampled=1") == {:error, :not_found}
  end

end
