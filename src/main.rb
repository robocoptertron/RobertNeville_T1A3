require "colorize"
require_relative "./config_manager"

config_manager = ConfigManager.new
config_errors = config_manager.init

if config_errors
  puts "Oops! There were some configuration errors:"
  config_errors.each do |error_message|
  puts error_message.red
  end
  puts "Please run the setup script to sort things out!"
  exit
end