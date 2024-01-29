module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class Request < CommandConnectors::Request
        attr_accessor :argv, :globalish_options, :inputs_argv, :action, :argument, :action_options

        def initialize(argv)
          self.argv = argv

          super()
        end

        def inputs
          @inputs ||= begin
            inputs_parser = InputsParser.new(command_class.inputs_type)
            result = inputs_parser.parse(inputs_argv)
            result.parsed
          end
        end

        def parse!
          globalish_parser = GlobalishParser.new

          result = globalish_parser.parse(argv)

          self.globalish_options = result.parsed

          action_parser = ActionParser.new(result.parsed[:help] ? :help : nil)

          result = action_parser.parse(result.remainder)

          self.action = result.action
          self.argument = result.argument
          self.action_options = result.parsed
          self.inputs_argv = result.remainder

          if action == :run
            unless argument
              raise ActionParseError, "Missing command to run"
            end
          end

          @is_parsed = true
        end

        # TODO: we might not have the full command name here... that should be fine.
        # TODO: rename this.
        def full_command_name
          argument
        end

        def action
          parse! unless parsed?
          @action
        end

        def argument
          parse! unless parsed?
          @argument
        end

        def parsed?
          @is_parsed
        end
      end
    end
  end
end

# banner
# additional_message
# environment
# program_name
# summarize
# warn
