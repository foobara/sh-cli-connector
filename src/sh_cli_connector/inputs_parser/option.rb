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

          def _non_colliding_path(full_paths)
            1.upto(full_path.length - 1) do |size|
              candidate_path = _truncated_path(full_path, size)
              match_count = _truncated_paths(full_paths, size).select { |path| path == candidate_path }.size

              if match_count == 1
                return candidate_path
              elsif match_count == 0
                # :nocov:
                raise "Not expecting to reach here"
                # :nocov:
              end
            end

            full_path
          end

          def _truncated_paths(paths, size)
            paths.map do |path|
              _truncated_path(path, size)
            end
          end

          def _truncated_path(path, size)
            path[(-size)..]
          end

          def to_args(short_options_used, full_paths)
            path = _non_colliding_path(full_paths)
            prefixed_name = path.join("_")
            long_option_name = Util.kebab_case(prefixed_name)
            short_option = attribute_name[0]

            argument_text = Util.constantify(prefixed_name)
            argument_text = "[#{argument_text}]" if boolean?

            args = ["--#{long_option_name} #{argument_text}"]

            # TODO: we should prioritize required options to get the short name in case of collision?
            unless short_options_used.include?(short_option)
              short_options_used << short_option
              args << "-#{short_option} #{argument_text}"
            end

            args << description if description

            args
          end

          def full_path
            [*prefix, attribute_name]
          end

          def required?
            is_required
          end

          def boolean?
            attribute_type.extends?(:boolean)
          end

          def array?
            attribute_type.extends?(:array)
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
