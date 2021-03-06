require "http"

module Weather
  API_URL = "https://api.open-meteo.com/v1/forecast?"
  DEGREES_IN_COMPASS = 360.0
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
    "south-southwest",
    "southwest",
    "west-southwest",
    "west",
    "west-northwest",
    "northwest",
    "north-northwest"
  ]
  DAILY_WEATHER_VARIABLES = [
    "weathercode",
    "temperature_2m_max",
    "temperature_2m_min",
    "apparent_temperature_max",
    "apparent_temperature_min",
    "sunrise",
    "sunset",
    "precipitation_sum",
    "precipitation_hours",
    "windspeed_10m_max",
    "winddirection_10m_dominant",
    "shortwave_radiation_sum"
  ]
  DEGREES_IN_COMPASS_SEGMENT = DEGREES_IN_COMPASS / WIND_DIRECTIONS.length

  def Weather.fetch_current(timezone, latitude, longitude)
    latitude_param = "latitude=#{latitude}"
    longitude_param = "longitude=#{longitude}"
    current_weather_param = "current_weather=true"
    timezone_param = "timezone=#{timezone}"
    response = nil
    begin
      params = "#{latitude_param}&#{longitude_param}&#{current_weather_param}&#{timezone_param}"
      response = HTTP.get("#{API_URL}#{params}")
    rescue HTTP::ConnectionError
      message = "Oops - there was a connection error. Make sure you're connected to the internet."
      {"error" => message}
    else
      # The fetch operation completed:
      if response.status.server_error?
        # The request was received but
        # there was a server error:
        {"error" => "Oops - there was a server error. You might have to try again later."}
      end
      # Occasionally an HTML page is returned
      # by this API. Make sure the response
      # data is parsable:
      data = nil
      begin
        data = response.parse
      rescue => e
        {"error" => "There was a problem parsing the data returned by the API: #{e.message}"}
      else
        # All good. Process the data for the app
        # and return it:
        current_weather = data["current_weather"]
        {
          "time" => current_weather["time"], 
          "temp" => current_weather["temperature"], 
          "wind_speed" => current_weather["windspeed"],
          "wind_direction" => self.translate_wind_direction(current_weather["winddirection"]),
          "weather" => self.translate_weather_code(current_weather["weathercode"])
        }
      end
    end
  end

  def Weather.fetch_coming_week(timezone, latitude, longitude)
    latitude_param = "latitude=#{latitude}"
    longitude_param = "longitude=#{longitude}"
    daily_weather_variables = Weather.daily_weather_variables
    timezone_param = "timezone=#{timezone}"
    response = nil
    begin
      params = "#{latitude_param}&#{longitude_param}&daily=#{daily_weather_variables}&#{timezone_param}"
      response = HTTP.get("#{API_URL}#{params}")
    rescue HTTP::ConnectionError
      message = "Oops - there was a connection error. Make sure you're connected to the internet."
      {"error" => message}
    else
      # The fetch operation completed:
      if response.status.server_error?
        # The request was received but
        # there was a server error:
        {"error" => "Oops - there was a server error. You might have to try again later."}
      end
      # Occasionally an HTML page is returned
      # by this API. Make sure the response
      # data is parsable:
      data = nil
      begin
        data = response.parse
      rescue => e
        {"error" => "There was a problem parsing the data returned by the API: #{e.message}"}
      else
        # All good. Process the data for the app
        # and return it:
        {"coming_week_weather" => Weather.process_coming_week_weather(data["daily"], data["daily_units"])}
      end
    end
  end

  def Weather.process_coming_week_weather(daily_variables, daily_units)
    # Generate an array of weather info hashes,
    # with each hash containing a single key - 
    # with the same name as the weather variable
    # returned by the API - that is assigned to
    # an internal hash storing the weather variable's
    #  "value" and "unit". Return the resulting
    # array:
    coming_week_weather = []
    for day in 0..6 do
      weather_info = {}
      daily_variables.each do |key, value|
        weather_info[key] = {
          "value" => value[day],
          "unit" => daily_units[key]
        }
      end
      coming_week_weather.push(weather_info)
    end
    coming_week_weather
  end

  def Weather.translate_wind_direction(wind_direction_degrees)
    # This method translates a given wind direction
    # in degrees to its corresponding compass direction.
    # There are 16 compass wind directions, and each
    # direction corresponds with a 22.5 degree segment
    # of the compass. Divide the wind direction degrees
    # by the segment magnitude and round down to get
    # the index of the corresponding nominal wind direction:
    compass_segment = (wind_direction_degrees / DEGREES_IN_COMPASS_SEGMENT).floor
    WIND_DIRECTIONS[compass_segment]
  end

  def Weather.translate_weather_code(weather_code)
    # This method translates a wheather
    # code to its corresponding condition
    # description (all descriptions) sourced
    # from Open-Meteo):
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
      "violent rain showers" # LOL
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

  def Weather.daily_weather_variables
    DAILY_WEATHER_VARIABLES.join(",")
  end
end

