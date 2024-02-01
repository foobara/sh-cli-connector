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

        attr_accessor :result
        attr_writer :parser

        def parse(argv)
          self.parser = nil
          self.result = Result.new

          result.remainder = parser.order(argv) do |nonopt|
            parser.terminate(nonopt)
          end

          validate_formats!

          result
        end

        def parser
          return @parser if @parser

          @parser = OptionParser.new
          setup_parser

          @parser
        end

        private

        def setup_parser
          parser.raise_unknown = false
          parser.set_summary_indent "  "

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

          parser.on("--stdin", "Read and parse inputs from stdin") do
            result.parsed[:stdin] = true
          end

          parser.on("--verbose", "Enable verbose output") do
            result.parsed[:verbose] = true
          end

          allowed_entity_depths = %w[aggregate atomic record-store]
          parser.on("--entity-depth DEPTH", allowed_entity_depths, "Set the entity depth") do |depth|
            result.parsed[:entity_depth] = depth
          end

          parser.on("--atomic", "Set the entity depth to atomic") do
            result.parsed[:entity_depth] = "atomic"
          end

          parser.on("--aggregate", "Set the entity depth to aggregate") do
            result.parsed[:entity_depth] = "aggregate"
          end

          parser.on("--record-store", "Set the entity depth to record-store") do
            result.parsed[:entity_depth] = "record_store"
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
