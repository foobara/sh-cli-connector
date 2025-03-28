module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Result
          attr_accessor :parsed, :remainder, :current_array

          def initialize
            self.parsed = {}
          end

          def validate!
            unless remainder.empty?
              # TODO: let's invert the order for single command mode: parse inputs first, then global from remainder,
              # and then raise if there's anything left
              raise ParseError, "Unexpected argument: #{remainder.first}"
            end
          end
        end

        attr_accessor :inputs_type, :parser, :current_array, :result

        def initialize(inputs_type)
          self.inputs_type = inputs_type
          self.parser = OptionParser.new

          setup_parser
        end

        def parse(argv)
          self.result = Result.new
          self.current_array = nil

          result.remainder = parser.order(argv) do |nonopt|
            if current_array
              current_array << nonopt
            else
              parser.terminate(nonopt)
            end
          end

          result.validate!

          result
        end

        private

        def setup_parser
          @option_set = nil

          parser.raise_unknown = false
          parser.set_summary_indent " "

          if inputs_type&.element_types&.any?
            attribute_to_option
            # This feels wrong but the parser callback needs to access our result.
            # TODO: figure out this smell and fix it
            option_set.prepare_parser(self)
          end
        end

        def option_set
          # TODO: this feels wrong to pass self here...
          @option_set ||= OptionSet.new
        end

        def attribute_to_option(
          attribute_name = nil,
          attribute_type: inputs_type,
          is_required: true,
          default: nil,
          prefix: []
        )
          options = InputsParser::Option.attribute_to_options(
            attribute_name,
            attribute_type:,
            prefix:,
            is_required:,
            default:
          )

          if options.is_a?(::Array)
            options.each do |option|
              option_set << option
            end
          else
            # Unreachable but would be reachable if we didn't require inputs to be attributes
            # :nocov:
            option_set << options
            # :nocov:
          end
        end
      end
    end
  end
end
