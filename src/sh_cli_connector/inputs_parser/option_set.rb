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
            long_option_paths = options.map(&:full_path)
            short_options_used = Set.new

            max_width = 30

            options.each do |option|
              args = option.to_args(short_options_used, long_option_paths)

              width = args.first.size

              if width > max_width
                max_width = width
              end

              parser.on(*args) do |value|
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

            parser.set_summary_width(max_width + 2)
          end
        end
      end
    end
  end
end
