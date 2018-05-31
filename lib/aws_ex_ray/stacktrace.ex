  defmodule AwsExRay.Stacktrace do

    def stacktrace(discard_num \\ 0) do

      {:current_stacktrace, list} = Process.info(self(), :current_stacktrace)

      # Ignore first and second
      # 0: AwsExRay.Util.stacktrace
      # 1: Process.info
      Enum.drop(list, 2 + discard_num) |> Enum.map(&to_map/1)

    end

    def to_map({module, fun, args, [file: path, line: line]}) do
      %{
        path: path,
        line: line,
        label: "#{module}.#{fun_name(fun)}/#{args}"
      }
    end

    defp fun_name(":" <> fun), do: fun
    defp fun_name(fun), do: fun

  end
