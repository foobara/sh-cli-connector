require "stringio"

module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Commands
        class Help < Command
          inputs request: :duck # TODO: have some way to specify by Ruby class...

          result :string

          def execute
            print_usage

            if single_command_mode?
              print_command_description
              print_command_input_options
            else
              if valid_argument?
                if argument_is_command?
                  print_command_description
                  print_command_input_options
                end
              else
                print_available_actions
                print_available_commands
              end

              print_global_options
            end

            output_string
          end

          def single_command_mode?
            command_connector.single_command_mode
          end

          def command_connector
            request.command_connector
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
            output.puts
            output.puts "WARNING: Unexpected argument: #{argument}"
            output.puts
          end

          def print_usage_without_argument
            usage = if single_command_mode?
                      "[INPUTS]"
                    else
                      "[GLOBAL_OPTIONS] [ACTION] [COMMAND_OR_TYPE] [COMMAND_INPUTS]"
                    end

            output.puts "Usage: #{program_name} #{usage}"
          end

          def print_usage_for_argument
            usage = "Usage: #{program_name} [GLOBAL_OPTIONS] #{argument} "

            usage += case argument
                     when "run"
                       "COMMAND_NAME [COMMAND_INPUTS]"
                     when "describe", "manifest"
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

          def command_registry
            command_connector.command_registry
          end

          def argument
            request.argument
          end

          def valid_argument?
            argument && (argument_is_action? || argument_is_command?)
          end

          def argument_is_command?
            !!command_class
          end

          def command_class
            return @command_class if defined?(@command_class)

            @command_class = if single_command_mode?
                               command_registry.all_transformed_command_classes.first
                             else
                               argument && command_registry.transformed_command_from_name(argument)
                             end
          end

          def argument_is_action?
            known_actions.include?(argument)
          end

          # TODO: maybe move this up the hierarchy?
          def known_actions
            %w[
              run
              describe
              manifest
              ping
              query_git_commit_info
              help
            ]
          end

          def print_available_actions
            output.puts
            output.puts "Available actions:"
            output.puts
            output.puts "  #{known_actions.join(", ")}"
            output.puts
            output.puts "Default action: run"
          end

          def print_available_commands
            output.puts
            output.puts "Available commands:"
            output.puts
            command_registry.each_transformed_command_class do |command_class|
              output.puts "  #{command_class.full_command_name}"
            end
          end

          def print_global_options
            output.puts
            output.puts "Global options:"
            output.puts
            output.puts request.globalish_parser.parser.summarize
          end

          def print_command_description
            description = command_class.description

            if description
              output.puts
              output.puts command_class.description
            end
          end

          def print_command_input_options
            output.puts
            output.puts single_command_mode? ? "Inputs:" : "Command inputs:"
            output.puts
            output.puts request.inputs_parser_for(command_class).parser.summarize
          end

          def output_string
            output.string
          end
        end
      end
    end
  end
end
