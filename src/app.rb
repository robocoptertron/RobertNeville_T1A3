require "prawn"

require_relative "./lib/console"
require_relative "./lib/geocode"
require_relative "./lib/timezone"
require_relative "./lib/weather"

class App
  LOCAL = "Local"
  ELSEWHERE = "Elsewhere"
  CURRENT = "Current"
  COMING_WEEK = "Coming week"
  PRINT_TO_CONSOLE = "Print to console"
  EXPORT_TO_PDF = "Export to PDF"

  def initialize(config_manager)
    @config_manager = config_manager
  end

  def exec(option)
    if !option
      self.main_loop
    else
      case option[:name]
      when "help"
        self.help
      when "config"
        self.config(option[:args])
      when "history"
        self.history(option[:args])
      end
    end
  end

  private

  def help
    puts "Usage information for CLIMate"
  end

  def config(args)
    case args.length
    when 1
      case args[0]
      when "list"
        self.print_config
      else
        Console.error("Invalid argument '#{args[0]}' for config option.")
      end
    when 3
      case args[0]
      when "set"
        self.set_config_option(args[1], args[2])
      else
        Console.error("Invalid argument '#{args[0]} for config option.'")
      end
    end
  end

  def print_config
    puts
    Console.info("Current CLIMate configuration:")
    @config_manager.general_config.each do |key, value|
      print key.yellow
      print ("-" * (30 - key.length) + "> ").blue
      print value.to_s
      puts
      puts
    end
  end

  def set_config_option(key, value)
    error = @config_manager.set_config_option(key, value)
    if error
      Console.error(error)
    else
      Console.success("Successfully set '#{key}' to '#{value}'!")
    end
  end

  def history(args)
    puts args
  end

  def exit_gracefully
    Console.info("Thanks for using CLIMate!")
    Console.info("Exiting")
    exit
  end

  def main_loop
    self.print_welcome_message
    timezone = self.get_timezone
    if !timezone
      Console.info("CLIMate needs to know your timezone to fetch forecasts.")
      self.exit_gracefully
    end
    begin
      while true
        location_type = self.select_location_type
        location_info = nil

        case location_type
        when LOCAL
          location_info = self.select_location_from_user_locations
          if !location_info
            # The user elected to search for a new location:
            message = "Enter a place name for your current location:"
            location_info = self.get_location_from_user(message)
            if location_info && !self.in_user_locations(location_info)
              save_location = Console.yes?("Would you like to save this location?")
              if save_location
                self.save_user_location(location_info) 
              end
            end
          end        
        when ELSEWHERE
          location_info = self.select_location_from_favourites
          if !location_info
            # The user elected to search for a new location:
            message = "Enter a place name to search for:"
            location_info = self.get_location_from_user(message)
            if location_info && !self.in_favourites(location_info)
              save_location = Console.yes?("Would you like to save this location?")
              if save_location
                self.save_favourite(location_info) 
              end
            end
          end
        end
        
        if !location_info
          if !Console.yes?("Would you like to view the weather for a different location?")
            self.exit_gracefully
          end
          next
        end

        forecast_type = self.select_forecast_type
        current_weather = nil
        weekly_forecast = nil

        case forecast_type
        when CURRENT
          current_weather = self.get_current_weather(timezone, location_info)
          if !current_weather
            message = "Sorry - CLIMate couldn't get weather data for #{location_info["display_name"]}"
            Console.info(message)
          else
            Console.success("Success!")
            self.print_current_weather(location_info["display_name"], current_weather)
          end
        when COMING_WEEK
          weekly_forecast = self.get_coming_week_weather(timezone, location_info)
          if !weekly_forecast
            message = "Sorry - CLIMate couldn't get weather data for #{location_info["display_name"]}"
            Console.info(message)
          else
            Console.success("Success!")
            output_type = self.select_output_type
            case output_type
            when PRINT_TO_CONSOLE
              self.print_coming_week_weather(location_info["display_name"], weekly_forecast)
            when EXPORT_TO_PDF
              self.generate_forecast_pdf(location_info["display_name"], weekly_forecast)
            end
          end
        end

        if current_weather || weekly_forecast
          if Console.yes?("Would you like to save this weather data to your history?")
            if current_weather
              self.save_to_history(location_info["display_name"], forecast_type, current_weather)
            elsif weekly_forecast
              self.save_to_history(location_info["display_name"], forecast_type, weekly_forecast)
            end
          end
        end

        if !Console.yes?("Would you like to view the weather for another location?")
          self.exit_gracefully
        end
      end
    rescue SignalException
      self.exit_gracefully
    end
  end

  def print_welcome_message
    puts
    puts "Welcome to CLIMate! You can use CTRL+C to exit at any time :)"
    puts
  end

  def get_timezone
    Console.info("Determining your timezone...")
    response = Timezone.get()
    if response["error"]
      Console.error(response["error"])
    else
      Console.success("Your timezone was detected as #{response["timezone"]}.")
      response["timezone"]
    end
  end

  def select_location_type
    message = "Please select a location type:"
    location_type_options = [LOCAL, ELSEWHERE]
    choice_index = Console.select(message, location_type_options)
    location_type_options[choice_index]
  end

  def select_location_from_user_locations
    return if self.user_locations.length == 0
    options = []
    self.user_locations.each { |location| options.push(location["display_name"])}
    options.push("Somewhere else")
    message = "Please select one of the following saved locations or 'Somewhere else' to enter a new one:"
    choice_index = Console.select(message, options)
    return if choice_index == options.length - 1
    self.user_locations[choice_index]
  end

  def user_locations
    @config_manager.user_locations["locations"]
  end

  def in_user_locations(location_info)
    self.user_locations.include?(location_info)
  end

  def save_user_location(location_info)
    error = @config_manager.add_user_location(location_info)
    if error
      Console.error(error)
    else
      Console.success("Successfully added #{location_info["display_name"]} to user locations!")
    end
  end

  def get_location_from_user(message)
    places_found = self.place_name_search_loop(message)
    return if !places_found
    options = []
    places_found.each { |place| options.push(place["display_name"]) }
    options.push("None of these")
    message = "Please choose the correct location from the following list of alternatives:"
    choice_index = Console.select(message, options)
    if choice_index == options.length - 1
      # The user selected 'None of these'.
      # Return nil:
      return
    end
    places_found[choice_index]
  end

  def place_name_search_loop(message)
    while true
      place_name = Console.ask(message)
      Console.info("Searching for '#{place_name}' geocode info...")
      search_results = Geocode.search_places_by_name(place_name)
      if search_results["error"]
        Console.error(search_results["error"])
        break if !Console.yes?("Try again?")
      else
        places_found = search_results["places_found"]
        if places_found.length == 0
          Console.info("Sorry - CLIMate couldn't find location info for '#{place_name}'.")
          break if !Console.yes?("Try again?")
        else
          return places_found
        end
      end
    end
  end

  def select_location_from_favourites
    return if self.favourites.length == 0
    message = "Would you like to choose a location from your favourites?"
    select_from_favourites = Console.ask(message)
    return if !select_from_favourites
    options = []
    self.favourites.each { |place| options.push(place["display_name"]) }
    options.push("Search for new location")
    message = "Here are your favourite locations. Please make a selection:"
    choice_index = Console.select(message, options)
    if choice_index == options.length - 1
      # The user selected 'Search for new location'.
      # Return nil:
      return
    end
    self.favourites[choice_index]
  end

  def favourites
    @config_manager.favourites["favourites"]
  end

  def in_favourites(location_info)
    self.favourites.include?(location_info)
  end

  def save_favourite(location_info)
    error = @config_manager.add_favourite(location_info)
    if error
      Console.error(error)
    else
      Console.success("Successfully added #{location_info["display_name"]} to favourites!")
    end
  end

  def select_forecast_type
    message = "Please select a weather forecast type:"
    forecast_type_options = [CURRENT, COMING_WEEK]
    choice_index = Console.select(message, forecast_type_options)
    forecast_type_options[choice_index]
  end

  def get_current_weather(timezone, location_info)
    Console.info("Fetching current weather data for #{location_info["display_name"]}...")
    results = Weather.fetch_current(
      timezone, 
      location_info["latitude"].to_f, 
      location_info["longitude"].to_f
    )
    if results["error"]
      Console.error(results["error"])
      return
    end
    results
  end

  def print_current_weather(place_name, current_weather)
    Console.info("Current weather for #{place_name}:")
    date_time = current_weather["time"].split("T")
    Console.print_weather_field("Date", date_time[0])
    Console.print_weather_field("Hour", date_time[1])
    Console.print_weather_field("Prevailing Conditions", current_weather["weather"])
    Console.print_weather_field("Temperature", current_weather["temp"])
    Console.print_weather_field("Wind Speed", "#{current_weather["wind_speed"]} km/h")
    Console.print_weather_field("Wind Direction", current_weather["wind_direction"])
    puts
  end

  def get_coming_week_weather(timezone, location_info)
    Console.info("Fetching the coming week's weather data for #{location_info["display_name"]}...")
    results = Weather.fetch_coming_week(
      timezone, 
      location_info["latitude"].to_f, 
      location_info["longitude"].to_f
    )
    if results["error"]
      Console.error(results["error"])
      return
    end
    results["coming_week_weather"]
  end

  def select_output_type
    message = "How would you like to view the results?"
    output_type_options = [PRINT_TO_CONSOLE, EXPORT_TO_PDF]
    choice_index = Console.select(message, output_type_options)
    output_type_options[choice_index]
  end

  def print_coming_week_weather(place_name, weather_data)
    Console.info("Coming week's weather for #{place_name}:")
    weather_data.each do |daily_forecast|
      Console.print_weather_field(
        "Date", 
        daily_forecast["time"]["value"]
      )
      Console.print_weather_field(
        "Min Temperature", 
        self.weather_variable_to_s(daily_forecast["temperature_2m_min"])
      )
      Console.print_weather_field(
        "Max Temperature", 
        self.weather_variable_to_s(daily_forecast["temperature_2m_max"])
      )
      Console.print_weather_field(
        "Min Apparent Temperature", 
        self.weather_variable_to_s(daily_forecast["apparent_temperature_min"])
      )
      Console.print_weather_field(
        "Max Apparent Temperature", 
        self.weather_variable_to_s(daily_forecast["apparent_temperature_max"])
      )
      Console.print_weather_field(
        "Precipitation Sum", 
        self.weather_variable_to_s(daily_forecast["precipitation_sum"])
      )
      Console.print_weather_field(
        "Precipitation Hours", 
        self.weather_variable_to_s(daily_forecast["precipitation_hours"])
      )
      Console.print_weather_field(
        "Expected Conditions", 
        Weather.translate_weather_code(daily_forecast["weathercode"]["value"])
      )
      Console.print_weather_field(
        "Sunrise", 
        daily_forecast["sunrise"]["value"].split("T")[1]
      )
      Console.print_weather_field(
        "Sunset", 
        daily_forecast["sunset"]["value"].split("T")[1]
      )
      Console.print_weather_field(
        "Max Windspeed", 
        self.weather_variable_to_s(daily_forecast["windspeed_10m_max"])
      )
      Console.print_weather_field(
        "Dominant Wind Direction", 
        Weather.translate_wind_direction(daily_forecast["winddirection_10m_dominant"]["value"])
      )
      Console.print_weather_field(
        "Shortwave Radiation Sum", 
        self.weather_variable_to_s(daily_forecast["shortwave_radiation_sum"])
      )
      puts
    end
  end

  def weather_variable_to_s(weather_variable)
    "#{weather_variable["value"]} #{weather_variable["unit"]}"
  end

  def generate_forecast_pdf(place_name, weather_data)
    filename = nil
    while !filename
      filename_input = Console.ask("Please enter a name for the file:")
      if filename_input == "." || filename_input == ".."
        Console.error("'.' and '..' are reserved filenames.")
        next
      end
      add_pdf_extension = true
      if filename_input.match(/\.pdf$/)
        add_pdf_extension = false
      end
      filename = @config_manager.general_config["output"] + "/#{filename_input}" + (add_pdf_extension ? ".pdf" : "")
    end
    
    proceed = true
    if File.exist?(filename)
      proceed = Console.yes?("'#{filename}' already exists. Do you want to overwrite it?")
    end

    if proceed
      Prawn::Fonts::AFM.hide_m17n_warning = true
      Prawn::Document.generate(filename) do |pdf|
        pdf.text "Weekly Weather Forecast for #{place_name}"
        pdf.text Time.now.inspect
        pdf.stroke_horizontal_rule
        pdf.move_down 20
        pdf.font "Courier"
        weather_data.each do |daily_forecast|
          pdf.text self.get_weather_field_string(
            "Date", 
            daily_forecast["time"]["value"]
          )
          pdf.text self.get_weather_field_string(
            "Min Temperature", 
            self.weather_variable_to_s(daily_forecast["temperature_2m_min"])
          )
          pdf.text self.get_weather_field_string(
            "Max Temperature", 
            self.weather_variable_to_s(daily_forecast["temperature_2m_max"])
          )
          pdf.text self.get_weather_field_string(
            "Min Apparent Temperature", 
            self.weather_variable_to_s(daily_forecast["apparent_temperature_min"])
          )
          pdf.text self.get_weather_field_string(
            "Max Apparent Temperature", 
            self.weather_variable_to_s(daily_forecast["apparent_temperature_max"])
          )
          pdf.text self.get_weather_field_string(
            "Precipitation Sum", 
            self.weather_variable_to_s(daily_forecast["precipitation_sum"])
          )
          pdf.text self.get_weather_field_string(
            "Precipitation Hours", 
            self.weather_variable_to_s(daily_forecast["precipitation_hours"])
          )
          pdf.text self.get_weather_field_string(
            "Expected Conditions", 
            Weather.translate_weather_code(daily_forecast["weathercode"]["value"])
          )
          pdf.text self.get_weather_field_string(
            "Sunrise", 
            daily_forecast["sunrise"]["value"].split("T")[1]
          )
          pdf.text self.get_weather_field_string(
            "Sunset", 
            daily_forecast["sunset"]["value"].split("T")[1]
          )
          pdf.text self.get_weather_field_string(
            "Max Windspeed", 
            self.weather_variable_to_s(daily_forecast["windspeed_10m_max"])
          )
          pdf.text self.get_weather_field_string(
            "Dominant Wind Direction", 
            Weather.translate_wind_direction(daily_forecast["winddirection_10m_dominant"]["value"])
          )
          pdf.text self.get_weather_field_string(
            "Shortwave Radiation Sum", 
            self.weather_variable_to_s(daily_forecast["shortwave_radiation_sum"])
          )
          pdf.move_down 40
        end
      end
      Console.success("Successfully exported weekly forecast to #{filename}!")
    else
      Console.info("Aborting PDF generation...")
    end
  end

  def get_weather_field_string(label, value)
    weather_field_string = label
    weather_field_string += ("-" * (30 - label.length) + "> ")
    weather_field_string += value
  end

  def save_to_history(place_name, forecast_type, weather_data)
    date_time = Time.new
    history_entry = {
      "date" => "#{date_time.year}-#{date_time.month}-#{date_time.day}",
      "time" => "#{date_time.hour}:#{date_time.min}-#{date_time.sec}",
      "location" => place_name,
      "forecast_type" => forecast_type,
      "weather_data" => weather_data
    }
    error = @config_manager.add_history_entry(history_entry)
    if error
      Console.error(error)
    else
      Console.success("Successfully added the weather data to your history!")
    end
  end
end