module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ArgvParser
        class Result
          attr_accessor :action, :argument, :globalish_options, :action_options, :inputs, :target
        end

        attr_accessor :raw_command_name, :command_class, :command_argv, :command_inputs

        def parse(argv)
          final_result = Result.new

          result = globalish_option_parser.parse(argv)

          final_result.globalish_options = result.parsed

          action_parser = ActionParser.new(result.parsed[:help] ? :help : nil)

          result = action_parser.parse(result.remainder)

          action = result.action
          argument = result.argument

          final_result.action = action
          final_result.argument = argument
          final_result.action_options = result.parsed

          if action == :run
            unless argument
              raise ActionParseError, "Missing command to run"
            end

            target = namespace.foobara_lookup_command(argument)

            unless target
              raise ActionParseError, "Command not found for #{argument}"
            end
          elsif argument
            target = namespace.foobara_lookup(argument)

            unless target
              raise ActionParseError, "Nothing found for #{argument}"
            end
          end

          final_result.target = target

          if result.action == :run
            inputs_parser = InputsParser.new(target.inputs_type)

            result = inputs_parser.parse(result.remainder)

            inputs = result.parsed

            final_result.inputs = inputs
          end

          final_result
        end

        def globalish_option_parser
          @globalish_option_parser ||= GlobalishParser.new
        end
      end
    end
  end
end

# some-org --globalish-opt=1 run --action-option=2 org-name:some-domain:some-command --input1=3 --input2=4

# 1. globalish parser
# 2. action parser
# 3. argument parser
# 4. command_parser
