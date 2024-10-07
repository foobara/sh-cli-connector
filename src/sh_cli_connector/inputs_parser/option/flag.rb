module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class Flag < Option
            class << self
              def applicable?(attribute_type)
                attribute_type.extends?(BuiltinTypes[:boolean])
              end

              def attribute_to_options(attribute_name, attribute_type:, prefix:, is_required:, default:)
                klasses = []

                klasses << OnFlag if default != true
                klasses << OffFlag if default != false

                if klasses.size == 1
                  klasses.first.new(
                    attribute_name:,
                    attribute_type:,
                    is_required:,
                    default:,
                    prefix:
                  )
                else
                  klasses.map do |klass|
                    klass.new(
                      attribute_name:,
                      attribute_type:,
                      is_required:,
                      default:,
                      prefix:
                    )
                  end
                end
              end
            end

            def _argument_text(_prefixed_name)
              nil
            end

            def array?
              false
            end
          end
        end
      end
    end
  end
end
