module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Serializers
        class CliResultSerializer < CommandConnectors::Serializers::AtomicSerializer
          def serialize(object)
            serializable = super

            io = StringIO.new

            print(io, serializable)

            io.puts
            io.string
          end

          private

          def print(io, object, depth = nil, after_colon: false)
            case object
            when ::Array
              if after_colon
                io.puts
              end

              depth = depth ? depth + 2 : 0

              object.each do |element|
                print(io, element, depth)
              end
            when ::Hash
              if after_colon
                io.puts
              end

              depth = depth ? depth + 2 : 0

              padding = " " * depth

              object.each_pair do |key, value|
                io.write padding
                io.write key
                io.write ":"
                print(io, value, depth, after_colon: true)
              end
            when ::String, ::Symbol, ::Numeric, ::TrueClass, ::FalseClass
              if after_colon
                io.write " "
              else
                io.write " " * depth
              end

              io.write object.inspect
            else
              # :nocov:
              raise "Unsupported type: #{object.class}"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
