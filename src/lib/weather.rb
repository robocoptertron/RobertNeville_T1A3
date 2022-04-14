require "http"

module Weather
  API_URL = "https://api.open-meteo.com/v1/forecast?"

  def Weather.fetch_current(timezone, location_info)
    latitude_param = "latitude=#{location_info[:latitude].to_f}"
    longitude_param = "longitude=#{location_info[:longitude].to_f}"
    current_weather_param = "current_weather=true"
    timezone_param = "timezone=#{timezone}"
    response = nil
    begin
      response = HTTP.get("#{API_URL}#{latitude_param}&#{longitude_param}&#{current_weather_param}&#{timezone_param}")
    rescue HTTP::ConnectionError
      message = "Oops - there was a connection error. Make sure you're connected to the internet."
      {error: message}
    else
      if response.status.server_error?
        {error: "Oops - there was a server error. You might have to try again later."}
      end
      data = response.parse
      data["current_weather"]
    end
  end
end

