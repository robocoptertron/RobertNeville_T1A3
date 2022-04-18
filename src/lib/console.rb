require "tty-prompt"
require "colorize"

module Console
  def Console.info(message)
    puts message
    puts
  end

  def Console.error(message)
    puts message.red
    puts
  end

  def Console.success(message)
    puts message.green
    puts
  end

  def Console.ask(message)
    prompt = TTY::Prompt.new
    answer = prompt.ask(message)
    puts
    answer
  end

  def Console.yes?(message)
    prompt = TTY::Prompt.new
    answer = prompt.yes?(message)
    puts
    answer
  end

  def Console.select(message, options)
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
    print label.yellow
    print ("-" * (30 - label.length) + "> ").blue
    print value
    puts
  end
end