defmodule AwsExRay.Store do

  @table :aws_ex_ray_traces

  def init() do
    :ets.new(@table, [:set, :public, :named_table])
  end

  def insert(trace, segment_id) do
    :ets.insert(@table, {self(), trace, segment_id})
  end

  def lookup(pid) do
    case :ets.lookup(@table, pid) do
      []                    -> {:error, :not_found}
      [{trace, segment_id}] -> {:ok, trace, segment_id}
    end
  end

  def delete() do
    :ets.delete(@table, self())
  end

end
