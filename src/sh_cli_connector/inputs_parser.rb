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
              # is this even possible?
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
          parser.raise_unknown = false
          parser.set_summary_indent "  "

          if inputs_type.element_types.any?
            attribute_to_option
          end
        end

        def attribute_to_option(
          attribute_name = nil,
          attribute_type: inputs_type,
          is_required: true,
          short_options_used: Set.new,
          default: nil,
          prefix: []
        )
          if attribute_type.extends_symbol?(:model) && !attribute_type.extends_symbol?(:entity)
            attribute_to_option(
              attribute_name,
              attribute_type: attribute_type.element_types,
              short_options_used:,
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
                short_options_used:,
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

            # TODO: implement
            long_option_paths = []

            parser.on(*option.to_args(short_options_used, long_option_paths)) do |value|
              if value.nil? && option.boolean?
                value = true
              end

              h = result.parsed

              option.prefix.each do |key|
                # TODO: should we support writing to arrays by index? If so we need to check inputs type to figure
                # out if we need to create a hash or an array here
                h = h[key] ||= {}
              end

              self.current_array = if array?
                                     h[attribute_name] = [value]
                                   else
                                     h[attribute_name] = value
                                     nil
                                   end
            end
          end
        end
      end
    end
  end
end
