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

          def print(io, object, padding = nil, after_colon: false)
            case object
            when ::Array
              if padding
                if after_colon
                  io.puts " ["
                else
                  io.puts "#{padding}["
                end
              end

              child_padding = padding ? "#{padding}  " : ""

              object.each.with_index do |element, index|
                print(io, element, child_padding)

                if index < object.size - 1
                  io.puts ","
                elsif padding
                  io.puts
                end
              end

              if padding
                io.write "#{padding}]"
              end
            when ::Hash
              if padding
                if after_colon
                  io.puts " {"
                else
                  io.puts "#{padding}{"
                end
              end

              child_padding = padding ? "#{padding}  " : ""

              object.each_pair.with_index do |(key, value), index|
                io.write child_padding
                io.write key
                io.write ":"
                print(io, value, child_padding, after_colon: true)
                if index < object.size - 1
                  io.puts ","
                elsif padding
                  io.puts
                end
              end

              if padding
                io.write "#{padding}}"
              end
            when ::String, ::Symbol, ::Numeric, ::TrueClass, ::FalseClass, ::NilClass
              if after_colon
                io.write " "
              else
                io.write padding
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
