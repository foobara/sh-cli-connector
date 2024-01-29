module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ActionParser
        class ActionParseError < StandardError; end

        class Result
          attr_accessor :parsed, :remainder, :action, :argument

          def initialize(action = nil)
            self.parsed = {}
            self.action = action
          end

          def action=(action)
            if @action
              raise ActionParseError, "Action already set"
            elsif argument
              raise ActionParseError, "Not expecting #{action} to appear after #{argument}"
            else
              @action = action
            end
          end

          def action
            @action || :run
          end

          def argument=(argument)
            if @argument
              raise ActionParseError, "Argument already set"
            end
          end

          def validate!
            if action == :run
              unless argument
                raise ActionParseError, "Missing command to run"
              end
            elsif action == :describe
              unless argument
                raise ActionParseError, "Missing command or type to describe"
              end
            end
          end
        end

        def initialize(action = nil)
          self.parser = OptionParser.new
          self.result = Result.new
          self.action = action
        end

        def parse(argv)
          begin
            result.remainder = parser.order(args) do |nonopt|
              case nonopt
              when "run", "describe", "manifest", "help"
                result.action = nonopt.to_sym
              else
                parser.terminate(nonopt)
              end
            end
            puts "out: #{out}"
            binding.pry
          rescue => e
            # TODO: catch correct exception here
            puts "in rescue: #{e}"
            binding.pry
          end

          result.validate!
          result
        end

        private

        def setup_parser
          parser.raise_unknown = true
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
