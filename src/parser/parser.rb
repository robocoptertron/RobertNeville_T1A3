require_relative "./argument_parser"

class Parser
  def initialize
    @parser = ArgumentParser.new
    @parser.add_option("help", "h", false, false, false, 0, 0)
    @parser.add_option("config", "c", true, false, false, 0, 2)
    @parser.add_option("history", "H", true, false, false, 0, 2)
  end

  def parse(argv)
    @parser.exec(argv)
    results = {
      args: @parser.parsed_args, 
      options: @parser.parsed_options, 
      errors: @parser.errors
    }
    results
  end
end