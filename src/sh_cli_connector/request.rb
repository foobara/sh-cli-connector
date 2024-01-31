module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ParseError < StandardError; end

      class Request < CommandConnectors::Request
        attr_accessor :argv,
                      :globalish_options,
                      :inputs_argv,
                      :action,
                      :argument,
                      :action_options,
                      :stdin,
                      :stdout,
                      :stderr,
                      :exit

        def initialize(argv, exit: true, stdout: $stdout, stderr: $stderr, stdin: $stdin)
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

        def input_serializer
          @input_serializer ||= begin
            input_format = globalish_options[:input_format]

            serializer_class = if input_format.nil?
                                 # TODO: refactor this to some default setting
                                 Serializers::YamlSerializer
                               else
                                 Serializer.serializer_from_symbol(input_format)
                               end

            unless serializer_class
              raise ParseError, "Unknown input format: #{input_format}"
            end

            serializer_class.new(nil)
          end
        end

        def output_serializer
          @output_serializer ||= begin
            output_format = globalish_options[:output_format]

            serializer_class = if output_format.nil?
                                 # TODO: refactor this to some default setting
                                 Serializers::YamlSerializer
                               else
                                 Serializer.serializer_from_symbol(output_format)
                               end

            unless serializer_class
              raise ParseError, "Unknown output format: #{output_format}"
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
                        inputs_parser = InputsParser.new(command_class.inputs_type)
                        result = inputs_parser.parse(inputs_argv)
                        result.parsed
                      end
        end

        private

        def parse!
          if argv.empty?
            self.action = "help"
            self.globalish_options = {}
          else
            globalish_parser = GlobalishParser.new

            result = globalish_parser.parse(argv)

            self.globalish_options = result.parsed

            action_parser = ActionParser.new

            result = action_parser.parse(result.remainder, starting_action: result.parsed[:help] ? "help" : nil)

            self.action = result.action
            self.argument = result.argument
            self.action_options = result.parsed
            self.inputs_argv = result.remainder
          end

          if action == "help"
            globalish_options[:output_format] = "noop"
          end
        end
      end
    end
  end
end
