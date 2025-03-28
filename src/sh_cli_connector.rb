module Foobara
  module CommandConnectors
    class AlreadyHasAConnectedCommand < StandardError; end

    class ShCliConnector < CommandConnector
      attr_accessor :program_name, :single_command_mode

      def initialize(*, program_name: File.basename($PROGRAM_NAME), single_command_mode: false, **, &)
        self.program_name = program_name

        connect_args = if single_command_mode
                         self.single_command_mode = true

                         if single_command_mode.is_a?(::Array)
                           single_command_mode
                         elsif single_command_mode.is_a?(::Class) && single_command_mode < Foobara::Command
                           [single_command_mode]
                         end
                       end

        super(*, **, &)

        if connect_args
          connect(*connect_args)
        end
      end

      def connect(...)
        super.tap do
          if single_command_mode
            if command_registry.size > 1
              raise AlreadyHasAConnectedCommand, "Can't have more than one command in single command mode"
            end
          end
        end
      end

      def build_request(*, **, &)
        command = if single_command_mode
                    command_registry.foobara_all_command.first
                  end

        self.class::Request.new(*, **, command:, &)
      end

      # TODO: this needs a better name... it's doing more than building.
      def build_response(request)
        response = super
        status = response.status
        out = response.status.zero? ? request.stdout : request.stderr

        out.puts response.body

        if request.exit
          exit status
        end

        response
      end

      def request_to_command(request)
        super
      rescue CommandConnector::NoCommandFoundError, ParseError => e
        request.error = e
        nil
      end

      def set_response_status(response)
        request = response.request

        response.status = if request.error
                            6
                          elsif request.success?
                            0
                          else
                            errors = request.error_collection.error_array
                            error = errors.first

                            case error
                            when CommandConnector::NotFoundError, Foobara::Entity::NotFoundError
                              # TODO: we should not be coupled to Entities here...
                              # :nocov:
                              2
                              # :nocov:
                            when CommandConnector::UnauthenticatedError
                              # :nocov:
                              3
                              # :nocov:
                            when CommandConnector::NotAllowedError
                              # :nocov:
                              4
                              # :nocov:
                            when CommandConnector::UnknownError
                              # :nocov:
                              5
                              # :nocov:
                            end || 1
                          end
      end

      def set_response_body(response)
        request = response.request

        response.body = if request.error
                          case request.error
                          when ParseError, CommandConnector::NotFoundError
                            request.error.message
                          else
                            # :nocov:
                            raise "Not sure how to handle error: #{request.error}"
                            # :nocov:
                          end
                        else
                          request.response_body
                        end
      end
    end
  end
end
