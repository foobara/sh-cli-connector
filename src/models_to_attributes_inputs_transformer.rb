# TODO: move this to a re-usable place?
module Foobara
  module CommandConnectors
    module ShCliConnector
      class ModelsToAttributesInputsTransformer < Foobara::TypeDeclarations::TypedTransformer
        class << self
          def input_type_declaration(previous_inputs_type)
            binding.pry
            {
              bbaassee: :string,
              exponent: :string
            }
          end
        end

        # Since attributes are castable to models, we can just use an identity function here
        def transform(inputs)
          inputs
        end
      end
    end
  end
end
