defmodule AwsExRay.Model.HTTPRequest do

  defstruct method:          nil,
            url:             nil,
            user_agent:      nil,
            client_ip:       nil,
            x_forwarded_for: nil,
            traced:          false

            # traced - 外に出ていくHTTP Requestの処理時間を計測する場合
            #          Subsegmentとして計測し、http.requestを埋め込む。
            #          その宛先のサービスがXRayに対応していてtraceを続ける場合は
            #          'traced'をtrueにする。HTTPのヘッダにはTraceのデータを突っ込む
end
