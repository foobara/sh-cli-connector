module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class OptionSet
          def options
            @options ||= []
          end

          def <<(option)
            options << option
          end

          def prepare_parser(result_source)
            parser = result_source.parser
            long_option_paths = []
            short_options_used = Set.new

            options.each do |option|
              parser.on(*option.to_args(short_options_used, long_option_paths)) do |value|
                if value.nil? && option.boolean?
                  value = true
                end

                h = result_source.result.parsed

                option.prefix.each do |key|
                  # TODO: should we support writing to arrays by index? If so we need to check inputs type to figure
                  # out if we need to create a hash or an array here
                  h = h[key] ||= {}
                end

                result_source.current_array = if option.array?
                                                h[option.attribute_name] = [value]
                                              else
                                                h[option.attribute_name] = value
                                                nil
                                              end
              end
            end
          end
        end
      end
    end
  end
end
