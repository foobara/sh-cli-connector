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
              "no-#{Util.kebab_case(prefixed_name)}"
            end
          end
        end
      end
    end
  end
end
