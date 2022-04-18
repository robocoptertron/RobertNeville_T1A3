require "fileutils"
require "json"
require_relative "./lib/console"

CONFIG_DIR = File.join(Dir.home, ".CLIMate")

GENERAL_CONFIG_FILE = File.join(CONFIG_DIR, "config.json")
USER_LOCATIONS_FILE = File.join(CONFIG_DIR, "locations.json")
FAVOURITES_FILE = File.join(CONFIG_DIR, "favourites.json")
HISTORY_FILE = File.join(CONFIG_DIR, "history.json")

CONFIG_FILES = [
  GENERAL_CONFIG_FILE, 
  USER_LOCATIONS_FILE, 
  FAVOURITES_FILE, 
  HISTORY_FILE
]

class ConfigManager
  def initialize
    @general_config = nil
    @user_locations = nil
    @favourites = nil
    @history = nil
  end

  def init
    validation_errors = self.validate_files

    if validation_errors.length == 0
      load_errors = []

      @general_config = self.load_config(GENERAL_CONFIG_FILE)
      if !@general_config
        load_errors.push("CONFIG ERROR: #{GENERAL_CONFIG_FILE}: configuration missing") 
      end

      @user_locations = self.load_config(USER_LOCATIONS_FILE)
      if !@user_locations
        load_errors.push("CONFIG ERROR: #{USER_LOCATIONS_FILE}: configuration missing")
      end
      
      @favourites = self.load_config(FAVOURITES_FILE)
      if !@favourites
        load_errors.push("CONFIG ERROR: #{FAVOURITES_FILE}: configuration missing")
      end
      
      @history = self.load_config(HISTORY_FILE)
      if !@history
        load_errors.push("CONFIG ERROR: #{HISTORY_FILE}: configuration missing")
      end

      load_errors.length == 0 ? nil : load_errors
    else
      validation_errors
    end
  end

  # Getters:

  def general_config
    @general_config
  end

  def user_locations
    @user_locations
  end

  def favourites
    @favourites
  end

  def history
    @history
  end

  # Update methods:

  def set_config_option(key, value)
    puts
    case key
    when "output"
      if File.exist?(value) && !File.directory?(value)
        Console.error("#{value} is a file - not a directory.")
      elsif !Dir.exist?(value)
        proceed = Console.yes?("#{value} does not yet exist. Would you like to create it?")
        if !proceed then return end
        FileUtils.mkdir_p(value)
      end
      @general_config["output"] = value
    end
    error = self.save_config_file(GENERAL_CONFIG_FILE, @general_config)
    if error
      error
    end
  end

  def add_user_location(location_info)
    @user_locations["locations"].push(location_info)
    @user_locations["locations"].sort_by! { |location| location["display_name"] }
    error = self.save_config_file(USER_LOCATIONS_FILE, @user_locations)
    if error 
      error
    end
  end

  def add_favourite(location_info)
    @favourites["favourites"].push(location_info)
    @favourites["favourites"].sort_by! { |location| location["display_name"] }
    error = self.save_config_file(FAVOURITES_FILE, @favourites)
    if error
      error
    end
  end

  def add_history_entry(history_entry)
    @history["history"].push(history_entry)
    @history["history"].sort_by! { |history_entry| Date.parse(history_entry["date"])}
    error = self.save_config_file(HISTORY_FILE, @history)
    if error
      error
    end
  end

  private

  # Save methods:

  def save_config_file(config_file_path, data_to_save)
    begin
      json = JSON.pretty_generate(data_to_save)
      file = File.open(config_file_path, "w")
      file.write(json)
      file.close
    rescue => error
      "There was a problem saving #{config_file_path}: #{error.message}"
    end
  end

  # Initialisation methods:

  def validate_files
    errors = []
    CONFIG_FILES.each do |file_path|
      if !self.exists?(file_path)
        message = "CONFIG ERROR: #{file_path}: file missing"
        errors.push(message)
      elsif self.directory?(file_path)
        message = "CONFIG ERROR: #{file_path}: file expected, directory found"
        errors.push(message)
      end
    end
    errors
  end

  def load_config(file_path)
    begin 
      file = File.open(file_path)
      contents = file.read
      file.close
      self.parse_json(contents)
    rescue
      nil
    end
  end

  # Helper methods:

  def parse_json(json)
    begin
      JSON.parse(json)
    rescue JSON::ParserError
      nil
    end
  end

  def exists?(file_path)
    File.exist?(file_path)
  end

  def directory?(file_path)
    File.directory?(file_path)
  end
end