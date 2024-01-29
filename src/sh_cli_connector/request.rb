module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class Request < CommandConnectors::Request
        attr_accessor :argv

        def initialize(argv)
          self.argv = argv

          super()
        end

        def inputs
          @inputs ||= command_parser.parse(command_args)
        end

        def parse
          remainder = globalish_options_parser.parse(argv)
        end

        def full_command_name
          unless defined?(@full_command_name)
            set_action_and_command_name
          end

          @full_command_name
        end

        def parsed_body
          body.empty? ? {} : JSON.parse(body)
        end

        def parsed_query_string
          if query_string.empty?
            {}
          else
            # TODO: override this in rack connector to use better rack utils
            CGI.parse(query_string).transform_values!(&:first)
          end
        end

        def action
          unless defined?(@action)
            set_action_and_command_name
          end

          @action
        end

        def set_action_and_command_name
          @action, @full_command_name = path[1..].split("/")
        end
      end
    end
  end
end

# banner
# additional_message
# environment
# program_name
# summarize
# warn
