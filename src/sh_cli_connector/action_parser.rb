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
              raise ParseError, "Action already set"
            elsif argument
              raise ParseError, "Not expecting #{action} to appear after #{argument}"
            else
              @action = action
            end
          end

          def argument=(argument)
            if @argument
              raise ParseError, "Argument already set"
            end

            @argument = argument
          end

          def validate!
            if action == "run"
              unless argument
                raise ParseError, "Missing command to run"
              end
            elsif action == :describe
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

          begin
            result.remainder = parser.order(argv) do |nonopt|
              if result.action.nil?
                if %w[run describe manifest help].include?(nonopt)
                  result.action = nonopt
                else
                  result.action = "run"
                  result.argument = nonopt
                end
              elsif argument.nil?
                result.argument = nonopt
                parser.terminate
              else
                parser.terminate(nonopt)
              end
            end
          rescue OptionParser::ParseError => e
            if e.args.size != 1
              raise "Unexpected ParseError argument count. Expected only 1 but got #{e.args.size}: #{e.args.inspect}"
            end

            # unclear why this needs to be caught...
            catch(:terminate) do
              parser.terminate(e.args.first)
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
