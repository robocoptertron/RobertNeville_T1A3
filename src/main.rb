require_relative "./lib/console"
require_relative "./config_manager"
require_relative "./parser/parser"
require_relative "./app"

config_manager = ConfigManager.new
config_errors = config_manager.init

if config_errors
  Console.info("Oops! There were some configuration errors:")
  config_errors.each do |error_message|
    Console.error(error_message)
  end
  Console.info("Please run the setup script to sort things out!")
  exit
end

parser = Parser.new # Initialize command line argument parser.
results = parser.parse(ARGV)

if results[:errors].length > 0
  # There were parsing errors, so display them and exit:
  Console.info("Please fix the following command line argument errors:")
  results[:errors].each_with_index do |error, i|
    Console.error("#{i + 1}. #{error}")
  end
  exit
end

arguments = results[:args]

if arguments.length > 0
  # This application does not support 
  # non-option arguments. Display errors
  # and exit:
  arguments.each do |arg|
    Console.error("Unexpected token: '#{arg}'")
  end
  exit
end

options = results[:options]

if options.length > 1
  # This application does not support
  # multiple options in the one command. 
  # Display errors and exit:
  Console.error("Please provide CLIMate with ONLY ONE option.")
  Console.info("You can use the '--help' or '-h' option for help :)")
  exit
end

app = App.new(config_manager)
app.exec(options[0])