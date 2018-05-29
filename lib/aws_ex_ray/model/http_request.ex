defmodule AwsExRay.Model.HTTPRequest do

  defstruct method:          nil,
            url:             nil,
            user_agent:      nil,
            client_ip:       nil,
            x_forwarded_for: nil,
            traced:          false

end
