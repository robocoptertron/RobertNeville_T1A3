require "colorize"
require_relative "./config_manager"
require_relative "./parser/parser"
require_relative "./app"

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

parser = Parser.new # Initialize command line argument parser.
results = parser.parse(ARGV)

if results[:errors].length > 0
  # There were parsing errors, so display them and exit:
  puts "Please fix the following command line argument errors:"
  results[:errors].each_with_index do |error, i|
    print "#{i + 1}. "
    puts error.red
  end
  exit
end

arguments = results[:args]

if arguments.length > 0
  # This application does not support 
  # non-option arguments. Display errors
  # and exit:
  arguments.each do |arg|
    puts "Unexpected token: '#{arg}'".red
  end
  exit
end

options = results[:options]

if options.length > 1
  # This application does not support
  # multiple options in the one command. 
  # Display errors and exit:
  puts "Please provide CLIMate with ONLY ONE option.".red
  puts "You can use the '--help' or '-h' option for help :)".green
  exit
end

app = App.new(config_manager)
app.exec(options[0])