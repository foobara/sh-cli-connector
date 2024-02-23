module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          attr_accessor :attribute_type, :attribute_name, :is_required, :prefix, :default

          def initialize(attribute_name:, attribute_type:, prefix:, is_required:, default:)
            self.attribute_type = attribute_type
            self.attribute_name = attribute_name
            self.prefix = prefix
            self.is_required = is_required
            self.default = default

            # TODO: support this
            # args << attributes_type.declaration_data[:one_of] if attributes_type.declaration_data.key?(:one_of)
          end

          def to_args(short_options_used, _long_option_paths)
            prefixed_name = [*prefix, attribute_name].join("__")
            long_option_name = Util.kebab_case(prefixed_name)
            short_option = attribute_name[0]
            argument_text = Util.constantify(prefixed_name)
            argument_text = "[#{argument_text}]" if boolean?

            args = ["--#{long_option_name} #{argument_text}"]

            unless short_options_used.include?(short_option)
              short_options_used << short_option
              args << "-#{short_option} #{argument_text}"
            end

            args << description

            args
          end

          def required?
            is_required
          end

          def boolean?
            attribute_type.extends_symbol?(:boolean)
          end

          def array?
            attribute_type.extends_symbol?(:array)
          end

          def description
            desc = []
            attributes_description = attribute_type.description

            if attributes_description && !BuiltinTypes.builtin?(attribute_type)
              desc << attributes_description
            end

            if required?
              desc << "Required"
            end

            if default
              desc << "Default: #{default.inspect}"
            end

            unless desc.empty?
              desc.map!.with_index do |d, index|
                break if index == desc.size - 1

                if d =~ /[\.!?\]\}:]$/
                  d
                else
                  "#{d}."
                end
              end

              desc.join(" ")
            end
          end
        end
      end
    end
  end
end
