module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class Attributes < Option
            class << self
              def applicable?(attribute_type)
                attribute_type.extends?(BuiltinTypes[:attributes])
              end

              def attribute_to_options(attribute_name, attribute_type:, prefix:, is_required:, default:)
                sub_required_attributes = if is_required
                                            attribute_type.declaration_data[:required] || []
                                          end || []

                defaults = attribute_type.declaration_data[:defaults] || {}

                attribute_type.element_types.map do |sub_attribute_name, sub_attribute_type|
                  Option.attribute_to_options(
                    sub_attribute_name,
                    attribute_type: sub_attribute_type,
                    prefix: [*prefix, *attribute_name],
                    is_required: is_required && sub_required_attributes.include?(sub_attribute_name),
                    default: defaults[sub_attribute_name]
                  )
                end.flatten
              end
            end
          end
        end
      end
    end
  end
end
