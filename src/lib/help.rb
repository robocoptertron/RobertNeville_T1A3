require "colorize"

module Help
  def Help.display
    # Display help information for the app:

    puts "./start.sh [option] [option_arg, ...]".yellow
    puts

    options = []

    # Add command line option usage information 
    # to the list for each option accepted
    # by the app:
    config_option = OptionInfo.new("config", "c", "Interact with the configuration system")
    config_option.add_arg("list", "lists all configuration variables", 0)
    config_option.add_arg("set", 
      "sets a specified configuration variable to the next command line argument provided", 2)
    options.push(config_option)

    history_option = OptionInfo.new("history", "H", "Interact with the history system")
    history_option.add_arg("purge", "Clears your weather forecast history", 0)
    options.push(history_option)
    
    # Output heading:
    puts "-----------------------------------------------------------"
    puts "VALID OPTIONS".green

    options.each do |option|
      # For each of the options,
      # display usage information:
      puts "-----------------------------------------------------------"
      puts "--#{option.name}".yellow
      puts
      print "Shorthand: " 
      print "-#{option.shorthand}".yellow
      puts
      puts
      puts "Description: #{option.description}"
      puts
      puts "Valid arguments:"
      puts
      option.args.each do |arg|
        print "'"
        print arg["name"].green
        print "'"
        print " #{arg["description"]}. "
        print "Requires #{arg["args"]} arguments.".red
        puts
      end
      puts
    end
  end

  private

  class OptionInfo
    # Class for objects that store
    # option usage information:
    attr_reader :name, :shorthand, :description, :args

    def initialize(name, shorthand, description)
      @name = name
      @shorthand = shorthand
      @description = description
      @args = []
    end

    def add_arg(name, description, args)
      @args.push({
        "name" => name,
        "description" => description,
        "args" => args
      })
    end
  end
  
end