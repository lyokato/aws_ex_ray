defmodule AwsExRay.Store.Table do

  @table :__aws_ex_ray__

  def init() do
    :ets.new(@table, [:set, :public, :named_table])
  end

  def insert(trace, segment_id) do
    :ets.insert(@table, {self(), trace, segment_id})
  end

  def lookup() do
    lookup(self())
  end
  def lookup(pid) do
    case :ets.lookup(@table, pid) do

      [] -> {:error, :not_found}

      [{_pid, trace, segment_id}|_] ->
        {:ok, trace, segment_id}

    end
  end

  def delete() do
    delete(self())
  end
  def delete(pid) do
    :ets.delete(@table, pid)
  end

end
