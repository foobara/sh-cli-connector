module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ActionParser
        class Result
          attr_accessor :parsed, :remainder
          attr_reader :action, :argument

          def initialize(action = nil)
            self.parsed = {}
            self.action = action
          end

          def action=(action)
            if @action
              # :nocov:
              raise ParseError.new(message: "Action already set")
              # :nocov:
            elsif argument
              # :nocov:
              raise ParseError.new(message: "Not expecting #{action} to appear after #{argument}")
              # :nocov:
            else
              @action = action
            end
          end

          def argument=(argument)
            if @argument
              # :nocov:
              raise ParseError.new(message: "Argument already set")
              # :nocov:
            end

            @argument = argument
          end

          def validate!
            if action.nil?
              raise ParseError.new(
                message: "Found invalid option #{remainder.first} but was expecting an action like 'run' or 'help'"
              )
            end

            if action == "run"
              unless argument
                raise ParseError.new(message: "Missing command to run")
              end
            elsif action == "describe"
              unless argument
                raise ParseError.new(message: "Missing command or type to describe")
              end
            end
          end
        end

        attr_accessor :parser

        def initialize
          self.parser = OptionParser.new
          setup_parser
        end

        def normalize_action(action)
          action
        end

        def parse(argv, starting_action: nil)
          result = Result.new
          result.action = starting_action

          result.remainder = parser.order(argv) do |positional_arg|
            if result.action.nil?
              positional_arg = normalize_action(positional_arg)

              # TODO: refactor this list of actions to a more reusable place
              if supported_actions.include?(positional_arg)
                result.action = positional_arg
              else
                result.action = "run"
                result.argument = positional_arg
              end
            elsif result.argument.nil?
              result.argument = positional_arg
              parser.terminate
            else
              parser.terminate(positional_arg)
            end
          end

          result.validate!
          result
        end

        def supported_actions
          ["run", "describe", "manifest", "help", "list"]
        end

        private

        def setup_parser
          parser.raise_unknown = false
          parser.set_summary_indent " "
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
