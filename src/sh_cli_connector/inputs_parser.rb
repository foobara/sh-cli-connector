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
          parser.set_summary_indent "  "

          if inputs_type.element_types.any?
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
          if attribute_type.extends_symbol?(:model) && !attribute_type.extends_symbol?(:entity)
            attribute_to_option(
              attribute_name,
              attribute_type: attribute_type.target_class.attributes_type,
              prefix:,
              is_required:,
              default:
            )
          elsif attribute_type.extends_symbol?(:attributes)
            sub_required_attributes = if is_required
                                        attribute_type.declaration_data[:required] || []
                                      end || []

            defaults = attribute_type.declaration_data[:defaults] || {}

            attribute_type.element_types.each_pair do |sub_attribute_name, sub_attribute_type|
              attribute_to_option(
                sub_attribute_name,
                attribute_type: sub_attribute_type,
                prefix: [*prefix, *attribute_name],
                is_required: is_required && sub_required_attributes.include?(sub_attribute_name),
                default: defaults[sub_attribute_name]
              )
            end
          else
            option = InputsParser::Option.new(
              attribute_name:,
              attribute_type:,
              prefix:,
              is_required:,
              default:
            )

            option_set << option

          end
        end
      end
    end
  end
end
