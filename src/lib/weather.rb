require "http"

module Weather
  API_URL = "https://api.open-meteo.com/v1/forecast?"
  WIND_DIRECTIONS = [
    "north", 
    "north-northeast", 
    "northeast", 
    "east-northeast",
    "east",
    "east-southeast",
    "southeast",
    "south-southeast",
    "south",

  ]

  def Weather.fetch_current(timezone, latitude, longitude)
    latitude_param = "latitude=#{latitude}"
    longitude_param = "longitude=#{longitude}"
    current_weather_param = "current_weather=true"
    timezone_param = "timezone=#{timezone}"
    response = nil
    begin
      response = HTTP.get("#{API_URL}#{latitude_param}&#{longitude_param}&#{current_weather_param}&#{timezone_param}")
    rescue HTTP::ConnectionError
      message = "Oops - there was a connection error. Make sure you're connected to the internet."
      {"error" => message}
    else
      if response.status.server_error?
        {"error" => "Oops - there was a server error. You might have to try again later."}
      end
      data = response.parse
      current_weather = data["current_weather"]
      {
        "time" => current_weather["time"], 
        "temp" => current_weather["temperature"], 
        "wind_speed" => current_weather["windspeed"],
        "wind_direction" => current_weather["winddirection"],
        "weather" => self.translate_weather_code(current_weather["weathercode"])
      }
    end
  end

  private

  def Weather.translate_weather_code(weather_code)
    case weather_code
    when 0
      "clear sky"
    when 1
      "mainly clear"
    when 2
      "partly cloudy"
    when 3
      "overcast"
    when 45
      "foggy"
    when 48
      "depositing rime fog"
    when 51
      "light drizzle"
    when 53
      "moderate drizzle"
    when 55
      "dense drizzle"
    when 56
      "light freezing drizzle"
    when 57
      "dense freezing drizzle"
    when 61
      "light rain"
    when 63
      "moderate rain"
    when 65
      "heavy rain"
    when 66
      "light freezing rain"
    when 67
      "heavy freezing rain"
    when 71
      "light snow fall"
    when 73
      "moderate snow fall"
    when 75
      "heavy snow fall"
    when 77
      "snow grains"
    when 80
      "light rain showers"
    when 81
      "moderate rain showers"
    when 82
      "voilent rain showers" # LOL
    when 85
      "light snow showers"
    when 86
      "heavy snow showers"
    when 95
      "light to moderate thunderstorms"
    when 96
      "thunderstorms with light hail"
    when 99
      "thunderstorms with heavy hail" 
    end
  end
end
