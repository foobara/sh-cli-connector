module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class Model < Option
            class << self
              def applicable?(attribute_type)
                attribute_type.extends?(BuiltinTypes[:model]) && !attribute_type.extends?(BuiltinTypes[:entity])
              end

              def attribute_to_options(
                attribute_name,
                attribute_type:,
                prefix:,
                is_required:,
                default:,
                always_prefix_inputs:
              )
                Option.attribute_to_options(
                  attribute_name,
                  attribute_type: attribute_type.target_class.attributes_type,
                  prefix:,
                  is_required:,
                  default:,
                  always_prefix_inputs:
                )
              end
            end
          end
        end
      end
    end
  end
end
