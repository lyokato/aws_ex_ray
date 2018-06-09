defmodule AwsExRay.Test.NestTest do
  use ExUnit.Case, async: true

  alias AwsExRay.Test.MockedSink
  alias AwsExRay.Trace
  use StructAssert

  setup do
    AwsExRay.Test.Mox.setup_default()
    :ok
  end

  test "nested subsegment" do

    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")
    seg = AwsExRay.start_tracing(trace, "MySegmentName")

      {:ok, sub1} = AwsExRay.start_subsegment("Sub1")

        {:ok, sub2} = AwsExRay.start_subsegment("Sub2")
        AwsExRay.finish_subsegment(sub2)

      AwsExRay.finish_subsegment(sub1)

    AwsExRay.finish_tracing(seg)

    [s1, s2, s3] = agent
                 |> MockedSink.get()
                 |> Enum.map(&Poison.decode!/1)

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
      "name" => "Sub1",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s2["parent_id"] == s1["id"]

    assert_subset(s3, %{
      "name" => "Sub2",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s3["parent_id"] == s2["id"]
  end

  test "nested subsegment on multi-processes" do

    agent = MockedSink.start_agent()

    {:ok, trace} = Trace.parse("Root=root1;Parent=parent1;Sampled=1")
    seg = AwsExRay.start_tracing(trace, "MySegmentName")

    caller = self()

    spawn(fn ->
      MockedSink.setup_on_process(agent)

      AwsExRay.Process.keep_tracing(caller)

      {:ok, sub1} = AwsExRay.start_subsegment("Sub1")

      caller2 = self()

      spawn(fn ->
        MockedSink.setup_on_process(agent)

        AwsExRay.Process.keep_tracing(caller2)

        {:ok, sub2} = AwsExRay.start_subsegment("Sub2")
        AwsExRay.finish_subsegment(sub2)

        send caller2, :finished

      end)

      receive do
        :finished -> :ok
      end

      AwsExRay.finish_subsegment(sub1)

      send caller, :finished
    end)

    receive do
      :finished -> :ok
    end


    AwsExRay.finish_tracing(seg)

    [s1, s2, s3] = agent
                 |> MockedSink.get()
                 |> Enum.map(&Poison.decode!/1)

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
      "name" => "Sub1",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s2["parent_id"] == s1["id"]

    assert_subset(s3, %{
      "name" => "Sub2",
      "metadata" => %{
        "tracing_sdk" => %{
          "name" => "aws-ex-ray",
          "version" => "0.0.1"
        }
      },
    })

    assert s3["parent_id"] == s2["id"]
  end

end
