require "tty-prompt"
require "colorize"
require_relative "./lib/geocode"
require_relative "./lib/timezone"
require_relative "./lib/weather"

LOCAL = "Local"
ELSEWHERE = "Elsewhere"

class App
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
    puts args
  end

  def history(args)
    puts args
  end

  def main_loop
    self.print_welcome_message
    timezone = self.get_timezone
    if !timezone
      puts "CLIMate needs to know your timezone to fetch forecasts."
      puts "Exiting..."
      exit
    end
    begin
      while true
        location_info = nil
        location_type = self.get_location_type_from_user
        case location_type
        when LOCAL
          location_info = self.get_location_info_from_user_locations
          if !location_info
            message = "Enter a place name for your current location:"
            location_info = self.get_location_info_from_user_input(message)
            if location_info
              save_location = self.ask("Would you like to save this location?")
              if save_location then self.save_user_location(location_info) end
            end
          end        
        when ELSEWHERE
          
        end
        
        if !location_info
          continue = self.continue_or_exit?
          next if continue
          self.exit_gracefully
        end

        weather_info = self.get_current_weather(timezone, location_info)

        if weather_info
          weather_info.each { |key, value| puts "#{key}: #{value}" }
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
    puts "Determining your timezone..."
    puts
    response = Timezone.get()
    if response["error"]
      self.display_error(response["error"])
      puts
    else
      puts "Your timezone was detected as #{response["timezone"]}.".green
      puts
      response["timezone"]
    end
  end

  def display_error(message)
    puts message.red
  end

  def continue_or_exit?
    self.ask("Would you like to continue using CLIMate?")
  end

  def get_location_type_from_user
    message = "Please select a weather forecast type:"
    location_type_options = [LOCAL, ELSEWHERE]
    choice_index = self.select(message, location_type_options)
    puts
    location_type_options[choice_index]
  end

  def get_location_info_from_user_locations
    user_locations = self.load_user_locations
    return if user_locations.length == 0
    options = []
    user_locations.each { |location| options.push(location["display_name"])}
    options.push("Somewhere else")
    message = "Here are some of your recent locations!\nSelect 'Somewhere else' to enter a new location:"
    choice_index = self.select(message, options)
    puts
    return if choice_index == options.length - 1
    user_locations[choice_index]
  end

  def load_user_locations
    @config_manager.user_locations["locations"]
  end

  def save_user_location(location_info)
    @config_manager.add_user_location(location_info)
  end

  def get_location_info_from_user_input(message)
    places_found = self.place_name_search_loop(message)
    return if !places_found
    display_names = []
    places_found.each { |place| display_names.push(place["display_name"]) }
    display_names.push("None of these")
    message = "Please choose the correct location from the following list of alternatives:"
    choice_index = self.select(message, display_names)
    puts
    if choice_index == display_names.length - 1
      # The user selected 'None of these'.
      # Return nil:
      return
    end
    places_found[choice_index]
  end

  def place_name_search_loop(message)
    while true
      place_name = self.ask(message)
      puts
      puts "Searching for '#{place_name}' geocode info..."
      puts
      search_results = Geocode.search_places_by_name(place_name)
      if search_results["error"]
        self.display_error(search_results["error"])
        break if !self.try_again?
      else
        places_found = search_results["places_found"]
        if places_found.length == 0
          puts "Sorry - CLIMate couldn't find location info for '#{place_name}'"
          puts
          break if !self.try_again?
        else
          return places_found
        end
      end
    end
    puts
  end

  def get_current_weather(timezone, location_info)
    puts "Fetching weather data for '#{location_info["display_name"]}'..."
    results = Weather.fetch_current(timezone, location_info["latitude"].to_f, location_info["longitude"].to_f)
    puts
    if results["error"]
      self.display_error(results["error"])
      puts
      return
    end
    results
  end

  def exit_gracefully
    puts
    puts "Thanks for using CLIMate!"
    puts "Exiting..."
    exit
  end

  # Prompt methods:

  def ask(message)
    prompt = TTY::Prompt.new
    prompt.ask(message)
  end

  def select(message, options)
    prompt = TTY::Prompt.new
    choice = prompt.select(message, options)
    options.each_with_index do |option, index|
      if option == choice
        return index
      end
    end
  end

  def try_again?
    prompt = TTY::Prompt.new
    prompt.yes?("Try again?")
  end
end