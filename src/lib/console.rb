require "tty-prompt"
require "colorize"

module Console
  def Console.info(message)
    # Print message in white:
    puts message
    puts
  end

  def Console.error(message)
    # Print message in red:
    puts message.red
    puts
  end

  def Console.success(message)
    # Print message in green:
    puts message.green
    puts
  end

  def Console.ask(message)
    # Ask the user a question (message)
    # and return their answer:
    prompt = TTY::Prompt.new
    answer = prompt.ask(message)
    puts
    answer
  end

  def Console.yes?(message)
    # Ask the user a yes/no question (message)
    # and return the boolean response:
    prompt = TTY::Prompt.new
    answer = prompt.yes?(message)
    puts
    answer
  end

  def Console.select(message, options)
    # Prompt the user to select from
    # options with a given message.
    # This method returns the index of
    # the user's choice in options:
    prompt = TTY::Prompt.new
    choice = prompt.select(message, options)
    options.each_with_index do |option, index|
      if option == choice
        puts
        return index
      end
    end
  end
  
  def Console.print_weather_field(label, value)
    # Print a weather variable in the
    # fomat of "variable_name------> value":
    print label.yellow
    print ("-" * (30 - label.length) + "> ").blue
    print value
    puts
  end
end