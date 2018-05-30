defmodule AwsExRay.Store do

  @store_key :__aws_ex_ray__

  def insert(trace, segment_id) do
    Process.put(@store_key, {trace, segment_id})
  end

  def lookup() do
    case Process.get(@store_key) do

      nil -> {:error, :not_found}

      {trace, segment_id} -> {:ok, trace, segment_id}

    end
  end

  def delete() do
    Process.delete(@store_key)
  end

end
