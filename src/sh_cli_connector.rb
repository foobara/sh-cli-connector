module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      # TODO: eliminate passing the command here...
      def request_to_response(request)
        command = request.command
        outcome = command.outcome

        # TODO: feels awkward to call this here... Maybe use result/errors transformers instead??
        # Or call the serializer here??
        body = command.respond_to?(:serialize_result) ? command.serialize_result : outcome.result

        # TODO: we should access these serializers as registered on the command connector to support adding more.
        output_format = request.globalish_options[:output_format]

        # TODO: encapsulate this logic elsewhere...
        serializer_class = if output_format.nil?
                             # TODO: make a CLI serializer for this case...
                             Serializers::YamlSerializer
                           else
                             Util.descendants(Serializer).find do |klass|
                               name = Util.non_full_name(klass)
                               name = name.gsub(/Serializer$/, "")
                               name = Util.underscore(name)

                               output_format == name
                             end
                           end

        unless serializer_class
          # TODO: should really raise this BEFORE running the command...
          raise "Unknown output format: #{request.globalish_options[:output_format]}"
        end

        serializer = serializer_class.new(request)
        body = serializer.serialize(body)

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
