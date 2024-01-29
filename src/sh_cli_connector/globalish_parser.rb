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
            result.parsed[:help] = help
          end

          parser.on("-f FORMAT", "--format FORMAT", "Set the input/output format (such as yaml or json)") do |format|
            result.parsed[:input_format] = format
            result.parsed[:output_format] = format
          end

          parser.on("--input-format FORMAT", "Set the input format (such as yaml or json)") do |format|
            result.parsed[:input_format] = format
          end

          parser.on("--output-format FORMAT", "Set the output format (such as yaml or json)") do |format|
            result.parsed[:output_format] = format
          end
        end
      end
    end
  end
end
