module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Serializers
        # TODO: move this to its own project
        class CliErrorsSerializer < CommandConnectors::Serializers::ErrorsSerializer
          def serialize(error_collection)
            Util.to_sentence(error_collection.map(&:message))
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
