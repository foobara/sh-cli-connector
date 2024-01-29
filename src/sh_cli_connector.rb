module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      # TODO: eliminate passing the command here...
      def command_to_response(command)
        outcome = command.outcome

        # TODO: feels awkward to call this here... Maybe use result/errors transformers instead??
        # Or call the serializer here??
        body = command.respond_to?(:serialize_result) ? command.serialize_result : outcome.result

        status = if outcome.success?
                   0
                 else
                   errors = outcome.errors

                   if errors.size == 1
                     error = errors.first

                     case error
                     when CommandConnector::NotFoundError, Foobara::Command::Concerns::Entities::NotFoundError
                       # TODO: we should not be coupled to Entities here...
                       2
                     when CommandConnector::UnauthenticatedError
                       3
                     when CommandConnector::NotAllowedError
                       4
                     when CommandConnector::UnknownError
                       5
                     end
                   end || 1
                 end

        Response.new(status:, body:)
      end
    end
  end
end
