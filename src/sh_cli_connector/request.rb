module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ParseError < StandardError; end

      class Request < CommandConnectors::Request
        attr_accessor :argv, :globalish_options, :inputs_argv, :action, :argument, :action_options

        def initialize(argv)
          self.argv = argv

          begin
            parse!
          rescue ParseError => e
            self.error = e
          end

          super()
        end

        # TODO: we might not have the full command name here... that should be fine.
        # TODO: rename this.
        def full_command_name
          argument
        end

        def inputs
          @inputs ||= begin
            inputs_parser = InputsParser.new(command_class.inputs_type)
            result = inputs_parser.parse(inputs_argv)
            result.parsed
          end
        end

        private

        def parse!
          globalish_parser = GlobalishParser.new

          result = globalish_parser.parse(argv)

          self.globalish_options = result.parsed

          action_parser = ActionParser.new

          result = action_parser.parse(result.remainder, starting_action: result.parsed[:help] ? "help" : nil)

          self.action = result.action
          self.argument = result.argument
          self.action_options = result.parsed
          self.inputs_argv = result.remainder
        end
      end
    end
  end
end
