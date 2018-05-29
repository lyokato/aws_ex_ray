defmodule AwsExRay.Plug.Paths do

  def include(list, conn) do
    path = "/" <> Enum.join(conn.path_info, "/")
    case Enum.find(list, fn p -> match(p, path, conn.method) end) do
      nil -> false
      _   -> true
    end
  end

  defp match({method, path}, conn_path, conn_meth) do
    path == conn_path && normalize_method(method) == normalize_method(conn_meth)
  end

  defp normalize_method(meth) when meth |> is_atom do
    normalize_method(to_string(meth))
  end
  defp normalize_method(meth) when meth |> is_binary do
    String.downcase(meth)
  end

end
