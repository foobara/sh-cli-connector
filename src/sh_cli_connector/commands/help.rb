module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Commands
        class Help < Command
          inputs request: :duck # TODO: have some way to specify by Ruby class...

          result :string

          def execute
            "helping!!"
          end
        end
      end
    end
  end
end
