module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Commands
        class Help < Command
          inputs request: :duck # TODO: have some way to specify by Ruby class...

          result :string

          def execute
            print_usage

            if argument_present_and_valid?
              if argument_is_command?
                print_command_description
                print_command_input_options
              end
            else
              print_available_actions
            end

            print_global_options

            output_string
          end

          def print_usage
            if argument
              if valid_argument?
                print_usage_for_argument
              else
                print_bad_argument_warning
                print_usage_without_argument
              end
            else
              print_usage_without_argument
            end
            "Usage: #{program_name}"
          end

          def print_bad_argument_warning
            output.puts "Unexpected argument: #{argument}"
          end

          def print_usage_without_argument
            output.puts "Usage: #{program_name} [GLOBAL_OPTIONS] [ACTION] [COMMAND_OR_TYPE] [COMMAND_INPUTS]"
          end

          def print_usage_for_argument
            usage = "Usage: #{program_name} [global options] #{argument} "

            usage += case argument
                     when "run"
                       "COMMAND_NAME [COMMAND_INPUTS]"
                     when "describe"
                       "COMMAND_OR_TYPE_NAME"
                     when "manifest"
                       "COMMAND_OR_TYPE_NAME"
                     when "ping", "query_git_commit_info"
                       ""
                     when "help"
                       "[ACTION_OR_COMMAND]"
                     else
                       "[COMMAND_INPUTS]"
                     end

            output.puts usage
          end

          def output
            @output ||= StringIO.new
          end

          def program_name
            command_connector.program_name
          end

          def command_connector
            request.command_connector
          end

          def valid_argument?
            # TODO: implement this
            true
          end

          def output_string
            output.string
          end
        end
      end
    end
  end
end
