module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class GlobalishParser
        class Result
          attr_accessor :parsed, :remainder

          def initialize
            self.parsed = {}
          end
        end

        attr_accessor :parser, :result

        def initialize
          self.parser = OptionParser.new
          setup_parser
        end

        def parse(argv)
          result = Result.new

          begin
            result.remainder = parser.order(args) do |nonopt|
              parser.terminate(nonopt)
            end
            puts "out: #{out}"
            binding.pry
          rescue => e
            # TODO: catch correct exception here
            puts "in rescue: #{e}"
            binding.pry
          end

          result
        end

        private

        def setup_parser
          parser.raise_unknown = true

          parser.on("-h", "--help", "Show this message") do |help|
            result[:help] = help
          end
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
