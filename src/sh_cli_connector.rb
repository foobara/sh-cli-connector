module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      attr_accessor :program_name

      def initialize(*, program_name: File.basename($PROGRAM_NAME), **opts, &)
        self.program_name = program_name
        super(*, **opts, &)

        add_default_inputs_transformer
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

      def request_to_response(request)
        if request.error
          case request.error
          when ParseError, CommandConnector::NoCommandFoundError
            return Response.new(status: 6, body: request.error.message, request:)
          else
            # :nocov:
            raise "Not sure how to handle error: #{request.error}"
            # :nocov:
          end
        end

        body = request.response_body

        status = if request.success?
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

        Response.new(status:, body:, request:)
      end
    end
  end
end
