require "http"

module Timezone
  API_URL = "http://worldtimeapi.org/api/ip"

  def Timezone.get
    response = nil
    begin
      response = HTTP.get(API_URL)
    rescue HTTP::ConnectionError
      message = "Oops - there was a connection error. Make sure you're connected to the internet."
      {"error" => message}
    else
      # The fetch operation completed:
      if response.status.server_error?
        # The request was received but there
        # was a server error:
        {"error" => "Oops - there was a server error. You might have to try again later."}
      end
      # Parse and return the data:
      data = response.parse
      {"timezone" => data["timezone"]}
    end
  end
end