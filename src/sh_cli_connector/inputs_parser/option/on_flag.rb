module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class OnFlag < Flag
            # rubocop:disable Naming/PredicateMethod
            def cast_value(value)
              unless value == true
                # :nocov:
                raise "This shouldn't happen. Please debug this!"
                # :nocov:
              end

              true
            end
            # rubocop:enable Naming/PredicateMethod
          end
        end
      end
    end
  end
end
