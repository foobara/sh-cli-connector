module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class OnFlag < Flag
            # rubocop:disable-next Naming/PredicateMethod
            def cast_value(value)
              unless value == true
                # simplecov:disable
                raise "This shouldn't happen. Please debug this!"
                # simplecov:enable
              end

              true
            end
          end
        end
      end
    end
  end
end
