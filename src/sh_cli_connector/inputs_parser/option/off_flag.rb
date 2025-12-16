require_relative "flag"

module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class OffFlag < Flag
            def supports_short_option?
              false
            end

            def _long_option_name(prefixed_name)
              "skip-#{Util.kebab_case(prefixed_name)}"
            end

            # rubocop:disable Naming/PredicateMethod
            def cast_value(value)
              unless value == true
                # Ruby's Optparser handles --no- but not --skip- prefixes. So we are implementing it ourselves.
                # :nocov:
                raise "This shouldn't happen. Please debug this!"
                # :nocov:
              end

              false
            end
            # rubocop:enable Naming/PredicateMethod
          end
        end
      end
    end
  end
end
