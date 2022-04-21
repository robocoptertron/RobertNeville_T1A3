require "prawn"

require_relative "./lib/console"
require_relative "./lib/geocode"
require_relative "./lib/help"
require_relative "./lib/timezone"
require_relative "./lib/weather"

class App
  # Constants for selection options:
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
    # Determine the app's course of exectution:
    if !option
      self.main_loop
    else
      case option["name"]
      when "help"
        self.help
      when "config"
        self.config(option["args"])
      when "history"
        self.history(option["args"])
      end
    end
  end

  private

  def help
    puts
    Console.info("Usage guide for CLIMate:")
    Help.display
  end

  def config(args)
    case args.length
    when 1
      case args[0]
      when "list"
        # Print all the configuration variables:
        self.print_config
      else
        Console.error("Invalid argument '#{args[0]}' for config option.")
      end
    when 3
      case args[0]
      when "set"
        # Set the configuration variable specified
        # by the second command line argument (args[1])
        # to the value specified by the third command
        # line argument (args[2]):
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
      # Print each of the configuration variables
      # in the format variable_name-------------> value:
      print key.yellow
      print ("-" * (30 - key.length) + "> ").blue
      print value.to_s
      puts
      puts
    end
  end

  def set_config_option(key, value)
    # Wrapper function for @config_manager.set_config_option,
    # which displays an appropriate message based on the
    # outcome:
    error = @config_manager.set_config_option(key, value)
    if error
      Console.error(error)
    else
      Console.success("Successfully set '#{key}' to '#{value}'!")
    end
  end

  def history(args)
    self.print_welcome_message
    case args.length
    when 0
      # No arguments were included with the
      # "history" option:
      begin
        while true
          if @config_manager.history["history"].length == 0
            # No history entries so exit:
            Console.info("You don't have any history entries.")
            break
          end

          # Prompt the user to select a date
          # from their history entries:
          history_date = self.select_history_date
          if !history_date
            # The user selected cancel
            self.exit_gracefully
          end

          # Get all history entries from 
          # the date selected by the user:
          history_entries = self.get_history_entries_from_date(history_date)
          
          # Prompt the user to select a history entry
          # from the list retrieved:
          history_entry = self.select_history_entry(history_entries)
          if !history_entry
            # THe user selected cancel
            self.exit_gracefully
          end

          case history_entry["forecast_type"]
          when CURRENT
            # The forecast type of the history entry 
            # is "Current". Print the data to the console:
            self.print_current_weather(history_entry["location"], history_entry["weather_data"])
          when COMING_WEEK
            # The forecast type of the history entry
            # is "Coming Week". Prompt the user
            # to select an output type:
            output_type = self.select_output_type
            case output_type
            when PRINT_TO_CONSOLE
              self.print_coming_week_weather(history_entry["location"], history_entry["weather_data"])
            when EXPORT_TO_PDF
              self.generate_forecast_pdf(history_entry["location"], history_entry["weather_data"])
            end
          end

          if !Console.yes?("Would you like to view more of your history?")
            self.exit_gracefully
          end
        end
      rescue SignalException
        self.exit_gracefully
      end
    when 1
      # Only one argument was included with the 
      # history option:
      case args[0]
      when "purge"
        # The argument is "purge". Confirm with the
        # user if they would like to proceed:
        if Console.yes?("Are you sure you want to purge your CLIMate history?")
          error = @config_manager.purge_history
          if error
            # An error was encountered whilst
            # overwriting the configuration - 
            # likely a filesystem error:
            Console.error(error)
          else
            Console.success("Purge successful!")
          end
        else
          # Cancel history purge:
          Console.info("Aborting purge")
        end
      else
        Console.error("Invalid argument '#{args[0]}' for history option.")
      end
    end
  end

  def select_history_date
    message = "Select a date to view history entries:"
    options = []
    @config_manager.history["history"].each { |entry| options.push(entry["date"])}
    options.uniq!
    options.push("Cancel")
    choice_index = Console.select(message, options)
    if choice_index == options.length - 1
      # The user selected cancel
      return
    end
    options[choice_index]
  end

  def get_history_entries_from_date(date)
    @config_manager.history["history"].select { |entry| entry["date"] == date}
  end

  def select_history_entry(entries)
    message = "Select the entry you would like to view from the list below:"
    options = []
    entries.each do |entry| 
      options.push("#{entry["forecast_type"]} @ #{entry["time"]}: #{entry["location"]}")
    end
    options.push("Cancel")
    choice_index = Console.select(message, options)
    if choice_index == options.length - 1
      # The user selected cancel
      return
    end
    entries[choice_index]
  end

  def exit_gracefully
    puts
    Console.info("Thanks for using CLIMate!")
    Console.info("Exiting")
    exit
  end

  def main_loop
    self.print_welcome_message
    # Get timezone from API:
    timezone = self.get_timezone
    if !timezone
      # No timezone - a connection error
      # is likely to have occurred:
      Console.info("CLIMate needs to know your timezone to fetch forecasts.")
      self.exit_gracefully
    end
    begin
      while true
        # Prompt user to select a location type:
        location_type = self.select_location_type
        location_info = nil

        case location_type
        when LOCAL
          # Location type selected by the user is
          # "Local" - see if they want to select
          # a location from their saved local
          # locations:
          location_info = self.select_location_from_user_locations
          if !location_info
            # Either the user has no saved local locations
            # or they selected to search for a new one, so
            # prompt them to enter a new one:
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
          # Location type selected by the user is
          # "Elsewhere" - see if they want to select
          # a location from their favourites:
          location_info = self.select_location_from_favourites
          if !location_info
            # Either the user has no favourites or they
            # selected to search for a new location, so
            # prompt them to enter a new one:
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
          # The user has searched for an invalid
          # location name, and responded with
          # no to "Try again?". Ask them if
          # They would like to try a different
          # location (continue using the app):
          if !Console.yes?("Would you like to view the weather for a different location?")
            self.exit_gracefully
          end
          next
        end

        # Prompt the user to select a forecast type:
        forecast_type = self.select_forecast_type
        current_weather = nil
        weekly_forecast = nil

        case forecast_type
        when CURRENT
          # Forecast type selected by the user is
          # "Current" - get current weather from
          # API:
          current_weather = self.get_current_weather(timezone, location_info)
          if !current_weather
            # Could not fetch weather data. There was likely
            # a connection error:
            message = "Sorry - CLIMate couldn't get weather data for #{location_info["display_name"]}"
            Console.info(message)
          else
            Console.success("Success!")
            self.print_current_weather(location_info["display_name"], current_weather)
          end
        when COMING_WEEK
          # Forecast type selected by the user is
          # "Coming Week" - get coming week weather
          # from API:
          weekly_forecast = self.get_coming_week_weather(timezone, location_info)
          if !weekly_forecast
            # Could not fetch weather data. There was likely
            # a connection error:
            message = "Sorry - CLIMate couldn't get weather data for #{location_info["display_name"]}"
            Console.info(message)
          else
            Console.success("Success!")
            # Prompt user to select an output
            # type for the forecast:
            output_type = self.select_output_type
            case output_type
            when PRINT_TO_CONSOLE
              # The user selected "Print to console":
              self.print_coming_week_weather(location_info["display_name"], weekly_forecast)
            when EXPORT_TO_PDF
              # The user selected "Export to PDF":
              self.generate_forecast_pdf(location_info["display_name"], weekly_forecast)
            end
          end
        end

        if current_weather || weekly_forecast
          # Either current or coming week weather data 
          # has been successfully retrieved. Save this
          # data to the user's history if they so
          # desire:
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
      # Catch CTRL+C
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
      # There was likely an connection error.
      # Implicitly return nil when method
      # terminates:
      Console.error(response["error"])
    else
      Console.success("Your timezone was detected as #{response["timezone"]}.")
      response["timezone"]
    end
  end

  def select_location_type
    # Prompt the user to select a
    # location type. Return the
    # selected option (string):
    message = "Please select a location type:"
    location_type_options = [LOCAL, ELSEWHERE]
    choice_index = Console.select(message, location_type_options)
    location_type_options[choice_index]
  end

  def select_location_from_user_locations
    # There are no saved user locations,
    # so return nil:
    return if self.user_locations.length == 0
    # Create a list of selection options
    # from the user locations' display names:
    options = []
    self.user_locations.each { |location| options.push(location["display_name"])}
    options.push("Somewhere else") # At last index in array.
    message = "Please select one of the following saved locations or 'Somewhere else' to enter a new one:"
    choice_index = Console.select(message, options)
    if choice_index == options.length - 1
      # The user selected "Somewhere else",
      # so return nil:
      return
    end
    self.user_locations[choice_index]
  end

  def user_locations
    @config_manager.user_locations["locations"]
  end

  def in_user_locations(location_info)
    self.user_locations.include?(location_info)
  end

  def save_user_location(location_info)
    # Wrapper function for @config_manager.add_user_location,
    # which displays an appropriate message based on the
    # outcome:
    error = @config_manager.add_user_location(location_info)
    if error
      Console.error(error)
    else
      Console.success("Successfully added #{location_info["display_name"]} to user locations!")
    end
  end

  def get_location_from_user(message)
    # Prompt the user to enter a place name for
    # a weather forecast:
    places_found = self.place_name_search_loop(message)
    return if !places_found
    # Create a list of selection options
    # from the found places' display names:
    options = []
    places_found.each { |place| options.push(place["display_name"]) }
    options.push("None of these") # At last index in array.
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
      # Get place name from user:
      place_name = Console.ask(message)
      Console.info("Searching for '#{place_name}' geocode info...")
      search_results = Geocode.search_places_by_name(place_name)
      if search_results["error"]
        # There was an error. Display the
        # error and exit the loop - 
        # implicitly return nil when loop
        # terminates:
        Console.error(search_results["error"])
        break if !Console.yes?("Try again?")
      else
        # Destructure places found from results:
        places_found = search_results["places_found"]
        if places_found.length == 0
          # No places found, so implicitly
          # return nil when loop terminates:
          Console.info("Sorry - CLIMate couldn't find location info for '#{place_name}'.")
          break if !Console.yes?("Try again?")
        else
          return places_found
        end
      end
    end
  end

  def select_location_from_favourites
    # No favourites - return nil:
    return if self.favourites.length == 0
    # Ask if the user would like to select
    # from their list of favourites:
    message = "Would you like to choose a location from your favourites?"
    select_from_favourites = Console.ask(message)
    return if !select_from_favourites
    # Prompt the user to select from their
    # list of favourites:
    options = []
    self.favourites.each { |place| options.push(place["display_name"]) }
    options.push("Search for new location") # At last index in array.
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
    # Wrapper function for @config_manager.add_favourite,
    # which displays an appropriate message based on the
    # outcome:
    error = @config_manager.add_favourite(location_info)
    if error
      Console.error(error)
    else
      Console.success("Successfully added #{location_info["display_name"]} to favourites!")
    end
  end

  def select_forecast_type
    # Prompt the user to select a
    # forecast type. Return the
    # selected option (string):
    message = "Please select a weather forecast type:"
    forecast_type_options = [CURRENT, COMING_WEEK]
    choice_index = Console.select(message, forecast_type_options)
    forecast_type_options[choice_index]
  end

  def get_current_weather(timezone, location_info)
    # Get current weather data from the API.
    # Return nil if no data is returned, otherwise
    # return the data:
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
    # Print each of the weather variables in the
    # format specified in Console.print_weather_field:
    Console.print_weather_field("Date", date_time[0])
    Console.print_weather_field("Hour", date_time[1])
    Console.print_weather_field("Prevailing Conditions", current_weather["weather"])
    Console.print_weather_field("Temperature", current_weather["temp"])
    Console.print_weather_field("Wind Speed", "#{current_weather["wind_speed"]} km/h")
    Console.print_weather_field("Wind Direction", current_weather["wind_direction"])
    puts
  end

  def get_coming_week_weather(timezone, location_info)
    # Get coming week weather data from the API.
    # Return nil if no data is returned, otherwise
    # return the data:
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
    # Prompt the user to select an ouput
    # type for weather data. Return the
    # selected option (string):
    message = "How would you like to view the results?"
    output_type_options = [PRINT_TO_CONSOLE, EXPORT_TO_PDF]
    choice_index = Console.select(message, output_type_options)
    output_type_options[choice_index]
  end

  def print_coming_week_weather(place_name, weather_data)
    Console.info("Coming week's weather for #{place_name}:")
    weather_data.each do |daily_forecast|
      # Print the weather variables for each day
      # in the format specified in Console.print_weather_field:
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
    # Return a weather variable's value followed
    # by its corresponding unit separated by a space:
    "#{weather_variable["value"]} #{weather_variable["unit"]}"
  end

  def generate_forecast_pdf(place_name, weather_data)
    filename = nil
    while !filename
      filename_input = Console.ask("Please enter a name for the file:")
      if filename_input == "." || filename_input == ".."
        # Filename input is a special directory on Unix based systems.
        Console.error("'.' and '..' are reserved filenames.")
        next
      end
      add_pdf_extension = true
      if filename_input.match(/\.pdf$/)
        # No PDF extension was included
        # in the user's input.
        add_pdf_extension = false
      end
      basename = filename_input + (add_pdf_extension ? ".pdf" : ""
      filename = @config_manager.general_config["output"] + "/#{basename}" )
    end
    
    proceed = true
    if File.exist?(filename)
      # The file already exists. Ask the user
      # if they want to overwrite it:
      proceed = Console.yes?("'#{filename}' already exists. Do you want to overwrite it?")
    end

    if proceed
      # Generate weekly forecast PDF:
      Prawn::Fonts::AFM.hide_m17n_warning = true
      Prawn::Document.generate(filename) do |pdf|
        pdf.text "Weekly Weather Forecast for #{place_name}"
        pdf.text Time.now.inspect
        pdf.stroke_horizontal_rule
        pdf.move_down 20
        pdf.font "Courier"
        weather_data.each do |daily_forecast|
          # Generate formatted fields for each weather
          # variable and add to PDF text:
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
      # The user does not want to overwrite
      # the file that already exists with
      # the same name as their input:
      Console.info("Aborting PDF generation...")
    end
  end

  def get_weather_field_string(label, value)
    # Returns a string formatted as "label-------------------------> value"
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