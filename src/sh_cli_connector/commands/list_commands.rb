module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Commands
        class ListCommands < CommandConnectors::Commands::ListCommands
          def verbose?
            request.globalish_options[:verbose]
          end
        end
      end
    end
  end
end
