defmodule AwsExRay.Test.ProcessTest do
  use ExUnit.Case, async: true

  use StructAssert

  alias AwsExRay.Test.MockedSink
  alias AwsExRay.Trace

  setup do
    AwsExRay.Test.Mox.setup_default()
    :ok
  end

  test "take over process" do

    agent = MockedSink.start_agent()

    # Start root segment
    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")
    seg = AwsExRay.start_tracing(trace, "MySegmentName")

    caller = self()

    spawn(fn ->

      assert {:error, :out_of_xray} == AwsExRay.start_subsegment("MySubsegment1")

      Process.sleep(10)

      send caller, :finished

    end)

    receive do
      :finished -> :ok
    end

    spawn(fn ->
      MockedSink.setup_on_process(agent)

      AwsExRay.Process.keep_tracing(caller)

      {:ok, subsegment} = AwsExRay.start_subsegment("MySubsegment2")

      Process.sleep(10)

      AwsExRay.finish_subsegment(subsegment)

      send caller, :finished

    end)

    receive do
      :finished -> :ok
    end

    AwsExRay.finish_tracing(seg)

    [got1, got2] = MockedSink.get(agent)

    s1 = Poison.decode!(got1)
    s2 = Poison.decode!(got2)

    assert_subset(s1, %{
      "name" => "MySegmentName",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert_subset(s2, %{
      "name" => "MySubsegment2",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s2["parent_id"] == s1["id"]

  end

  test "segment stack automatically deleted when process is dead" do

    caller = self()

    pid = spawn(fn ->

      {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")
      segment = AwsExRay.start_tracing(trace, "MySubsegment1")

      Process.sleep(10)

      assert AwsExRay.Store.Table.lookup() == {:ok, trace, segment.id, []}

      send caller, :finished

    end)

    receive do
      :finished -> :ok
    end

    Process.sleep(10)

    assert AwsExRay.Store.Table.lookup(pid) == {:error, :not_found}

  end

end
