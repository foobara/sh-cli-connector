module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      def request_to_command(argv)
        parser = ArgvParser.new(command_registry)
        parse_result = parser.parse(argv)

        binding.pry
        action = request.action
        inputs = nil

        full_command_name = request.full_command_name

        case action
        when "run"
          transformed_command_class = command_registry[full_command_name]

          unless transformed_command_class
            # :nocov:
            raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
            # :nocov:
          end

          inputs = request.inputs
        when "describe"
          manifestable = transformed_command_from_name(full_command_name) || type_from_name(full_command_name)

          unless manifestable
            # :nocov:
            raise NoCommandOrTypeFoundError, "Could not find command or type registered for #{full_command_name}"
            # :nocov:
          end

          command_class = Foobara::CommandConnectors::Commands::Describe
          full_command_name = command_class.full_command_name

          inputs = { manifestable: }
          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        when "describe_command"
          transformed_command_class = transformed_command_from_name(full_command_name)

          unless transformed_command_class
            # :nocov:
            raise NoCommandFoundError, "Could not find command registered for #{full_command_name}"
            # :nocov:
          end

          command_class = Foobara::CommandConnectors::Commands::Describe
          full_command_name = command_class.full_command_name

          inputs = { manifestable: transformed_command_class }
          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        when "describe_type"
          type = type_from_name(full_command_name)

          unless type
            # :nocov:
            raise NoTypeFoundError, "Could not find type registered for #{full_command_name}"
            # :nocov:
          end

          command_class = Foobara::CommandConnectors::Commands::Describe
          full_command_name = command_class.full_command_name

          inputs = { manifestable: type }
          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        when "manifest"
          command_class = Foobara::CommandConnectors::Commands::Describe
          full_command_name = command_class.full_command_name

          inputs = { manifestable: self }
          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        when "ping"
          command_class = Foobara::CommandConnectors::Commands::Ping
          full_command_name = command_class.full_command_name

          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        when "query_git_commit_info"
          # TODO: this feels out of control... should just accomplish this through run I think instead. Same with ping.
          command_class = Foobara::CommandConnectors::Commands::QueryGitCommitInfo
          full_command_name = command_class.full_command_name

          transformed_command_class = command_registry[full_command_name] || transform_command_class(command_class)
        else
          # :nocov:
          raise InvalidContextError, "Not sure what to do with #{action}"
          # :nocov:
        end

        transformed_command_class.new(inputs)
      end

      # TODO: eliminate passing the command here...
      def command_to_response(command)
        outcome = command.outcome

        # TODO: feels awkward to call this here... Maybe use result/errors transformers instead??
        # Or call the serializer here??
        body = command.respond_to?(:serialize_result) ? command.serialize_result : outcome.result

        status = if outcome.success?
                   200
                 else
                   errors = outcome.errors

                   if errors.size == 1
                     error = errors.first

                     case error
                     when CommandConnector::UnknownError
                       500
                     when CommandConnector::NotFoundError, Foobara::Command::Concerns::Entities::NotFoundError
                       # TODO: we should not be coupled to Entities here...
                       404
                     when CommandConnector::UnauthenticatedError
                       401
                     when CommandConnector::NotAllowedError
                       403
                     end
                   end || 422
                 end

        headers = headers_for(command)

        Response.new(status, headers, body)
      end

      def headers_for(_command)
        static_headers.dup
      end

      def static_headers
        @static_headers ||= ENV.each_with_object({}) do |(key, value), headers|
          match = key.match(/\AFOOBARA_HTTP_RESPONSE_HEADER_(.*)\z/)

          if match
            header_name = match[1].downcase.tr("_", "-")
            headers[header_name] = value
          end
        end.freeze
      end
    end
  end
end
