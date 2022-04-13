class ArgumentParser

  def initialize()
    @options = []
    @parsed_args = []
    @parsed_options = []
    @errors = []
  end

  def exec(argv)
    total_number_of_arguments = argv.length
    current_arg_index = 0

    while current_arg_index < total_number_of_arguments

      current_arg = argv[current_arg_index]
      
      if !self.is_option(current_arg)
        # Current arg is not an option.
        # Add it to the list of parsed
        # arguments:
        @parsed_args.push(current_arg)
        current_arg_index += 1
        next
      end

      if current_arg.match(/^-+$/)
        # Only hyphens have been provided.
        # Add error accordingly:
        @errors.push({
          message: "An empty option ('#{current_arg}') has been provided."
        })
        current_arg_index += 1
        next
      end

      parsed_opt = {}

      if self.is_verbose_option(current_arg)
        
        # Current arg is a verbose option - 
        # it is prefixed with 2 hyphens.
      
        if self.is_key_value_option(current_arg)
            # The option is in the form of a 
            # key/value pair

            parsed_opt[:name] = self.get_option_key(current_arg)

            if !self.is_valid_option(parsed_opt[:name])
              # Not a valid option - add error to
              # the list of parsing errors:
              @errors.push({
                option: parsed_opt[:name],
                message: "#{parsed_opt[:name]} is not a key/value option."
              })
            else
              # Valid option - add option 
              # to the parsed options list:
              parsed_opt[:key_value] = true
              parsed_opt[:value] = self.get_option_value(current_arg)
              parsed_options.push(parsed_opt)
            end

            current_arg_index += 1
            next
        else
          parsed_opt[:name] = current_arg[2..-1]
        end
      end

      if !parsed_opt[:name]
        # Option name has not been set yet

        # The option is in shorthand form (may be a group of options):
        opt_group_string = current_arg[1..-1] # Strip hyphen
        opt_group_array = self.split_option_group(opt_group_string)
        number_of_options = opt_group_array.length

        opt_group_string.chars.each_with_index do |opt, i|
          if !self.is_valid_option(opt)
            @errors.push({
              option: opt,
              message: "#{opt} is not a valid option."
            })
            opt_group_array.delete_at(i)
          end
        end

        if opt_group_array.length < number_of_options
          # Some of the options in the current argument
          # are invalid, so move on to the next argument:
          current_arg_index += 1
          next
        end

        if opt_group_array.length == 1
          # There is only one option -
          # it might accept arguments:
          parsed_opt[:name] = self.get_option_name_from_shorthand(opt_group_array[0])
        else
          # There are multiple options, so
          # none of them will accept arguments.
          # Add each to the parsed options list:
          opt_group_array.each do |opt|
            name = self.get_option_name_from_shorthand(opt)
            @parsed_options.push(name)
          end
          current_arg_index += 1
          next
        end
      end

      current_arg_index += 1

      if !self.is_valid_option(parsed_opt[:name])
        # The argument is an invalid option - add a new
        # error to the list and start analysing the next
        # argument:
        @errors.push({
          option: parsed_opt[:name],
          message: "#{parsed_opt[:name]} is not a valid option."
        })
        next
      end

      config_opt = self.get_option_by_name(parsed_opt[:name])
      
      if !config_opt[:accepts_args]
        # The option does not accept arguments -
        # add the option to the list of parsed
        # options
        @parsed_options.push(parsed_opt)
        next
      end

      # The option accepts arguments. Search the remaining 
      # command line arguments for aguments for the option:

      arguments_remaining = total_number_of_arguments - current_arg_index + 1
      option_aguments = []
      while current_arg_index < arguments_remaining
        next_arg = argv[current_arg_index]
        if self.is_option(next_arg)
          # Found the next option. Cease
          # searching for arguments
          break
        else
          option_arguments.push(next_arg)
        end

        current_arg_index += 1

        break if option_arguments.length == config_opt[:max_args]
      end

      if option_arguments.length < config_opt[:min_args]
        # The number of arguments provided for the
        # option is less than the minimum required:
        @errors.push({
          option: parsed_opt[:name],
          message: "#{parsed_opt[:name]} requires a minimum of #{config_opt[:min_args]} arguments."
        })
        next
      end

      parsed_opt[:arguments] = option_arguments

      @parsed_options.push(parsed_opt)
    end
  end

  def add_option(name, shorthand, accepts_args, key_value, groupable, min_args, max_args)
    @options.push({
      name: name,
      shorthand: shorthand,
      accepts_args: accepts_args,
      key_value: key_value,
      groupable: groupable,
      min_args: min_args,
      max_args: max_args
    })
  end

  def print_options
    puts @options
  end

  def is_option(arg)
    arg[0] == '-'
  end

  def is_verbose_option(arg)
    arg[0] == '-' && arg[1] == '-'
  end

  def is_key_value_option(arg)
    arg.include?("=")
  end

  def get_option_key(arg)
    # Remove leading hyphens
    stripped_arg = arg[2..-1]
    stripped_arg[0..arg.index("=")]
  end

  def get_option_value(arg)
    arg[arg.index("=")..-1]
  end

  def split_option_group(opt_group_string)
    opt_group_string.chars
  end

  def is_valid_option(name)
    @options.select { |option| option[:name] == name || option[:shorthand] == name }.length > 0
  end

  def get_option_name_from_shorthand(shorthand)
    opt = @options.select { |option| option[:shorthand] == shorthand }[0]
    opt[:name]
  end

  def get_option_by_name(name)
    option = @options.select { |opt| opt[:name] = name }[0]
    option
  end

  def parsed_options
    @parsed_options
  end

  def parsed_args
    @parsed_args
  end

  def errors
    @errors
  end
end