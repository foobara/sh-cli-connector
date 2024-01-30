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
              raise ParseError, "Action already set"
              # :nocov:
            elsif argument
              # :nocov:
              raise ParseError, "Not expecting #{action} to appear after #{argument}"
              # :nocov:
            else
              @action = action
            end
          end

          def argument=(argument)
            if @argument
              # :nocov:
              raise ParseError, "Argument already set"
              # :nocov:
            end

            @argument = argument
          end

          def validate!
            if action.nil?
              raise ParseError,
                    "Found invalid option #{remainder.first} but was expecting an action like 'run' or 'help'"
            end

            if action == "run"
              unless argument
                raise ParseError, "Missing command to run"
              end
            elsif action == "describe"
              unless argument
                raise ParseError, "Missing command or type to describe"
              end
            end
          end
        end

        attr_accessor :parser

        def initialize
          self.parser = OptionParser.new
          setup_parser
        end

        def parse(argv, starting_action: nil)
          result = Result.new
          result.action = starting_action

          result.remainder = parser.order(argv) do |nonopt|
            if result.action.nil?
              if %w[run describe manifest help].include?(nonopt)
                result.action = nonopt
              else
                result.action = "run"
                result.argument = nonopt
              end
            elsif result.argument.nil?
              result.argument = nonopt
              parser.terminate
            else
              parser.terminate(nonopt)
            end
          end

          result.validate!
          result
        end

        private

        def setup_parser
          parser.raise_unknown = false
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
