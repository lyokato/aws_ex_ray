defmodule AwsExRay.Store.Table do

  @moduledoc ~S"""
  This module provies functions to handle ETS table which contains
  process-and-segment mapping information.
  """

  alias AwsExRay.Trace

  @table :__aws_ex_ray__

  @spec init() :: :ok
  def init() do
    :ets.new(@table, [:set, :public, :named_table])
    :ok
  end

  @spec insert(
    trace       :: Trace.t,
    segment_id  :: String.t,
    subsegments :: list
  ) :: :ok
  def insert(trace, segment_id, subsegments \\ []) do
    :ets.insert(@table, {self(), trace, segment_id, subsegments})
    :ok
  end

  @spec lookup()
  :: {:ok, Trace.t, String.t, list}
  |  {:error, :not_found}

  def lookup() do
    lookup(self())
  end

  @spec lookup(pid :: pid)
  :: {:ok, Trace.t, String.t, list}
  |  {:error, :not_found}

  def lookup(pid) do
    case :ets.lookup(@table, pid) do

      [] -> {:error, :not_found}

      [{_pid, trace, segment_id, subsegments}|_] ->
        {:ok, trace, segment_id, subsegments}

    end
  end

  @spec push_subsegment(String.t) :: :ok
  def push_subsegment(subsegment_id) do
    case lookup() do

      {:error, :not_found} -> :ok

      {:ok, trace, segment_id, subsegments} ->
        insert(trace, segment_id, [subsegment_id|subsegments])

    end
  end

  @spec pop_subsegment(String.t) :: :ok
  def pop_subsegment(subsegment_id) do
    case lookup() do

      {:error, :not_found} -> :ok

      {:ok, trace, segment_id, subsegments} ->
        insert(trace,
               segment_id,
               List.delete(subsegments, subsegment_id))

    end
  end

  @spec delete() :: :ok
  def delete() do
    delete(self())
  end

  @spec delete(pid :: pid) :: :ok
  def delete(pid) do
    :ets.delete(@table, pid)
    :ok
  end

end
