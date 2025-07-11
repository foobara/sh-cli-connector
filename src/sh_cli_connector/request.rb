module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ParseError < Foobara::Error
        context({})
      end

      class Request < CommandConnector::Request
        attr_accessor :argv,
                      :single_command_mode,
                      :command,
                      :globalish_options,
                      :inputs_argv,
                      :action,
                      :argument,
                      :action_options,
                      :stdin,
                      :stdout,
                      :stderr,
                      :exit

        def initialize(argv, command:, exit: true, stdout: $stdout, stderr: $stderr, stdin: $stdin)
          self.command = command
          self.argv = argv
          self.exit = exit
          self.stdin = stdin
          self.stdout = stdout
          self.stderr = stderr

          begin
            parse!
          rescue ParseError => e
            self.error = e
          end

          super()
        end

        def single_command_mode?
          !!command
        end

        def input_serializer
          @input_serializer ||= begin
            input_format = globalish_options[:input_format]

            serializer_class = if input_format.nil?
                                 # TODO: refactor this to some default setting
                                 Foobara::CommandConnectors::Serializers::YamlSerializer
                               else
                                 Serializer.serializer_from_symbol(input_format)
                               end

            unless serializer_class
              # :nocov:
              raise ParseError.new(message: "Unknown input format: #{input_format}")
              # :nocov:
            end

            serializer_class.new(nil)
          end
        end

        # TODO: we might not have the full command name here... that should be fine.
        # TODO: rename this.
        def full_command_name
          argument
        end

        def inputs
          @inputs ||= if globalish_options[:stdin]
                        input_serializer.deserialize(stdin.read)
                      else
                        result = inputs_parser.parse(inputs_argv)
                        result.parsed
                      end
        end

        def inputs_parser
          @inputs_parser ||= inputs_parser_for
        end

        def inputs_parser_for(command_class = self.command_class)
          InputsParser.new(command_class.inputs_type, always_prefix_inputs: command_connector.always_prefix_inputs)
        end

        def globalish_parser
          @globalish_parser ||= GlobalishParser.new
        end

        def action_parser
          @action_parser ||= ActionParser.new
        end

        private

        def parse!
          if single_command_mode?
            parse_single_command!
          else
            parse_multi_command!
          end

          if action == "help"
            globalish_options[:output_format] = "noop"
          elsif action == "list"
            globalish_options[:output_format] = "cli_tabular"
          end

          validate_parse_result!

          set_serializers
        end

        def parse_single_command!
          self.globalish_options = {}

          if argv == ["--help"]
            self.action = "help"
          else
            self.action = "run"
            # TODO: needs to be the only registered command
            self.argument = command
            self.inputs_argv = argv
            self.command_class = command.command_class
          end
        end

        def parse_multi_command!
          if argv.empty?
            self.action = "help"
            self.globalish_options = {}
          else
            result = globalish_parser.parse(argv)

            self.globalish_options = result.parsed

            starting_action = globalish_options[:action]

            result = action_parser.parse(result.remainder, starting_action:)

            self.action = result.action
            self.argument = result.argument
            self.action_options = result.parsed
            self.inputs_argv = result.remainder
          end
        end

        def validate_parse_result!
          if ["help", "list"].include?(action)
            # This gives some leniency around where the global options are when there's no command
            result = globalish_parser.parse(inputs_argv)

            if result.remainder.any?
              # :nocov:
              raise ParseError.new(message: "Found invalid options #{globalish_parser.remainder}")
              # :nocov:
            end

            globalish_options.merge!(result.parsed)
          end
        end

        def set_serializers
          format = globalish_options[:output_format]

          format ||= if globalish_options[:stdin]
                       :yaml
                     else
                       [Serializers::CliResultSerializer, Serializers::CliErrorsSerializer]
                     end

          entity_depth = globalish_options[:entity_depth]

          @serializers = [*format, *entity_depth]
        end
      end
    end
  end
end
