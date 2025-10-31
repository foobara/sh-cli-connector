module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class InputsParser
        class Option
          class << self
            def attribute_to_options(
              attribute_name,
              attribute_type:,
              prefix:,
              is_required:,
              default:,
              always_prefix_inputs:
            )
              [Model, Attributes, Flag].each do |klass|
                if klass.applicable?(attribute_type)
                  return klass.attribute_to_options(
                    attribute_name,
                    attribute_type:,
                    prefix:,
                    is_required:,
                    default:,
                    always_prefix_inputs:
                  )
                end
              end

              new(
                attribute_name:,
                attribute_type:,
                prefix:,
                is_required:,
                default:,
                always_prefix_inputs:
              )
            end
          end

          attr_accessor :attribute_type, :attribute_name, :is_required, :prefix, :default, :always_prefix_inputs

          def initialize(
            attribute_name:,
            attribute_type:,
            prefix:,
            is_required:,
            default:,
            always_prefix_inputs:
          )
            self.attribute_type = attribute_type
            self.attribute_name = attribute_name
            self.prefix = prefix
            self.is_required = is_required
            self.default = default
            self.always_prefix_inputs = always_prefix_inputs

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
            prefixed_name = _prefixed_name(full_paths)
            long_option_name = _long_option_name(prefixed_name)

            argument_text = _argument_text(prefixed_name)

            args = if argument_text
                     ["--#{long_option_name} #{argument_text}"]
                   else
                     ["--#{long_option_name}"]
                   end

            if supports_short_option?
              short_option = attribute_name[0]
              # TODO: we should prioritize required options to get the short name in case of collision?
              unless short_options_used.include?(short_option)
                short_options_used << short_option
                args << if argument_text
                          "-#{short_option} #{argument_text}"
                        else
                          "-#{short_option}"
                        end
              end
            end

            args << description if description

            args
          end

          def supports_short_option?
            true
          end

          def _prefixed_name(full_paths)
            if always_prefix_inputs
              full_path.join("_")
            else
              _non_colliding_path(full_paths).join("_")
            end
          end

          def _long_option_name(prefixed_name)
            Util.kebab_case(prefixed_name)
          end

          def _argument_text(prefixed_name)
            Util.constantify(prefixed_name)
          end

          def full_path
            [*prefix, attribute_name]
          end

          def required?
            is_required
          end

          def array?
            attribute_type.extends?(BuiltinTypes[:array])
          end

          def has_default?
            !default.nil?
          end

          def primitive?
            attribute_type.primitive?
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

            unless primitive?
              one_of = attribute_type.declaration_data[:one_of]

              if one_of && !one_of.empty?
                desc << "One of: #{one_of.join(", ")}"
              end
            end

            if has_default?
              displayed_default = default.is_a?(String) ? default : default.inspect
              desc << "Default: #{displayed_default}"
            end

            unless desc.empty?
              desc.map!.with_index do |d, index|
                break if index == desc.size - 1

                if d =~ /[.!?\]}:]$/
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
