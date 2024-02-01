module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Serializers
        # TODO: move this to its own project
        class ErrorsSerializer < Serializer
          def serialize(errors)
            Util.to_sentence(errors.map(&:message))
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
