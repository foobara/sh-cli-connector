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

          short_options_used = Set.new
          required = inputs_type.declaration_data[:required] || []

          inputs_type.element_types.each_pair do |attribute_name, attribute_type|
            attribute_to_option(
              attribute_name,
              attribute_type:,
              short_options_used:,
              is_required: required.include?(attribute_name)
            )
          end
        end

        def attribute_to_option(attribute_name, attribute_type:, short_options_used:, is_required:, prefix: [])
          if attribute_type.extends_symbol?(:attributes)
            sub_required_attributes = if is_required
                                        attribute_type.declaration_data[:required] || []
                                      end || []

            attribute_type.element_types.each_pair do |sub_attribute_name, sub_attribute_type|
              attribute_to_option(
                sub_attribute_name,
                attribute_type: sub_attribute_type,
                short_options_used:,
                prefix: [*prefix, attribute_name],
                is_required: is_required && sub_required_attributes.include?(sub_attribute_name)
              )
            end
          else
            is_boolean = attribute_type.extends_symbol?(:boolean)
            is_array = attribute_type.extends_symbol?(:array)

            prefixed_name = [*prefix, attribute_name].join("__")
            long_option_name = Util.kebab_case(prefixed_name)
            short_option = attribute_name[0]
            argument_text = Util.constantify(prefixed_name)
            argument_text = "[#{argument_text}]" if is_boolean

            args = ["--#{long_option_name} #{argument_text}"]

            unless short_options_used.include?(short_option)
              short_options_used << short_option
              args << "-#{short_option} #{argument_text}"
            end

            description = attribute_type.description

            if description && !BuiltinTypes.builtin?(attribute_type)
              args << description
            end

            # TODO: support these
            # args << attributes_type.description
            # args << attributes_type.declaration_data[:one_of] if attributes_type.declaration_data.key?(:one_of)

            parser.on(*args) do |value|
              if value.nil? && is_boolean
                value = true
              end

              h = result.parsed

              prefix.each do |key|
                # TODO: should we support writing to arrays by index? If so we need to check inputs type to figure
                # out if we need to create a hash or an array here
                h = h[key] ||= {}
              end

              self.current_array = if is_array
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
