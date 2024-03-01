# TODO: move this to a re-usable place?
module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      class ModelsToAttributesInputsTransformer < TypeDeclarations::TypedTransformer
        class << self
          def type_declaration(from_type)
            if from_type.extends_symbol?(:entity)
              from_type.target_class.primary_key_type
            elsif from_type.extends_symbol?(:model)
              from_type.target_class.attributes_type
            elsif from_type.extends_symbol?(:tuple)
              # TODO: implement this logic for tuple
              # :nocov:
              raise "Tuple not yet supported"
              # :nocov:
            elsif from_type.extends_symbol?(:array)
              element_type = from_type.element_type

              if element_type
                declaration_data = Util.deep_dup(from_type.declaration_data)

                declaration_data[:element_type_declaration] = type_declaration(element_type)

                declaration_data
              else
                from_type
              end
            elsif from_type.extends_symbol?(:attributes)
              declaration_data = Util.deep_dup(from_type.declaration_data)

              declaration_data[:element_type_declarations] = from_type.element_types.transform_values do |element_type|
                type_declaration(element_type)
              end

              declaration_data
            elsif from_type.extends_symbol?(:associative_array)
              # TODO: implement this
              # :nocov:
              raise "Associative array not yet supported"
              # :nocov:
            else
              from_type
            end
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
