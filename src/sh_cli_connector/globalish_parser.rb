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

        def parse(argv)
          self.result = Result.new
          self.parser = OptionParser.new
          setup_parser

          result.remainder = parser.order(argv) do |nonopt|
            parser.terminate(nonopt)
          end

          validate_formats!

          result
        end

        private

        def setup_parser
          parser.raise_unknown = false

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

        def validate_formats!
          [result.parsed[:input_format], result.parsed[:output_format]].compact.uniq.each do |format|
            if format
              unless Serializer.serializer_from_symbol(format)
                raise ParseError, "Unknown format: #{format}"
              end
            end
          end
        end
      end
    end
  end
end
