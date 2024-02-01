module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Serializers
        class CliTabularSerializer < CommandConnectors::Serializer
          def serialize(table)
            io = StringIO.new

            table.each do |row|
              row = Util.array(row)

              row.each do |column|
                io.puts column if column
              end
            end

            io.string
          end
        end
      end
    end
  end
end
