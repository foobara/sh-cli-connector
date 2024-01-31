module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
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

        command = request.command
        outcome = command.outcome

        # TODO: feels awkward to call this here... Maybe use result/errors transformers instead??
        # Or call the serializer here??
        body = command.respond_to?(:serialize_result) ? command.serialize_result : outcome.result
        body = request.output_serializer.serialize(body)

        status = if outcome.success?
                   0
                 else
                   errors = outcome.errors

                   if errors.size == 1
                     error = errors.first

                     case error
                     when CommandConnector::NotFoundError, Foobara::Command::Concerns::Entities::NotFoundError
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
                     end
                   end || 1
                 end

        Response.new(status:, body:, request:)
      end
    end
  end
end
