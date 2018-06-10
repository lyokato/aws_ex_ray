defmodule AwsExRayTest do
  use ExUnit.Case, async: true

  use StructAssert

  alias AwsExRay.Test.MockedSink
  alias AwsExRay.Trace
  alias AwsExRay.Util

  setup do
    AwsExRay.Test.Mox.setup_default()
    :ok
  end

  test "segment" do

    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")

    t1 = Util.now()

    Process.sleep(5)

    seg = AwsExRay.start_tracing(trace, "MySegmentName")

    Process.sleep(5)

    t2 = Util.now()

    Process.sleep(5)

    AwsExRay.finish_tracing(seg)

    Process.sleep(5)

    t3 = Util.now()

    [got] = MockedSink.get(agent)
    s1 = Poison.decode!(got)

    assert s1["start_time"] > t1
    assert s1["start_time"] < t2

    assert s1["end_time"] > t2
    assert s1["end_time"] < t3

    assert_subset(s1, %{
      "name" => "MySegmentName",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

  end

  test "simple tracing" do

    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")

    AwsExRay.trace(trace, "SimpleWay", fn ->
      Process.sleep(10)
    end)

    [got] = MockedSink.get(agent)
    s1 = Poison.decode!(got)

    assert_subset(s1, %{
      "name" => "SimpleWay",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

  end

  test "simple tracing with annotations" do

    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")

    AwsExRay.trace(trace, "SimpleWay", %{"MyLogicType1" => "Foobar", "MyLogicType2" => "Barbuz"}, fn ->
      Process.sleep(10)
    end)

    [got] = MockedSink.get(agent)
    s1 = Poison.decode!(got)

    assert_subset(s1, %{
      "name" => "SimpleWay",
      "annotations" => %{
        "MyLogicType1" => "Foobar",
        "MyLogicType2" => "Barbuz",
      },
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

  end

  test "simple subsegment" do
    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")

    result = AwsExRay.trace(trace, "SimpleWay", fn ->

      Process.sleep(10)

      sub_result = AwsExRay.subsegment("SimpleSub",
                                       fn _trace_value ->

        Process.sleep(10)

        1

      end)

      Process.sleep(10)

      sub_result + 2

    end)

    assert result == 3

    [s1, s2] = agent |> MockedSink.get() |> Enum.map(&Poison.decode!/1)

    assert_subset(s1, %{
      "name" => "SimpleWay",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert_subset(s2, %{
      "name" => "SimpleSub",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s2["parent_id"] == s1["id"]

  end

  test "simple subsegment with annotations" do
    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")

    AwsExRay.trace(trace, "SimpleWay", fn ->

      Process.sleep(10)

      annotations = %{"MyLogic" => "Job1"}

      AwsExRay.subsegment("SimpleSub",
                          annotations,
                          [namespace: :none],
                          fn _trace_value ->

        Process.sleep(10)

      end)

      Process.sleep(10)

    end)

    [s1, s2] = agent |> MockedSink.get() |> Enum.map(&Poison.decode!/1)

    assert_subset(s1, %{
      "name" => "SimpleWay",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert_subset(s2, %{
      "name" => "SimpleSub",
      "annotations" => %{
        "MyLogic" => "Job1",
      },
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s2["parent_id"] == s1["id"]

  end

end
