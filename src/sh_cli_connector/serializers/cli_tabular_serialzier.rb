require "io/console/size"

module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Serializers
        # TODO: refactor much of this logic to Util?
        class CliTabularSerializer < CommandConnectors::Serializer
          PAD_SIZE = 1

          def serialize(table)
            return "" if table.empty?

            io = StringIO.new

            widths = column_widths(table)
            widths = adjust_to_preserve_final_column_width(widths)

            cellified_table = cellify(table, widths)

            cellified_table.each do |row|
              max_lines = row.map(&:size).max

              lines = []

              row.each.with_index do |cell, index|
                is_last_column = index == row.size - 1
                width = widths[index]

                cell.each.with_index do |line, line_index|
                  lines[line_index] ||= ""
                  line = pad(line, width) unless is_last_column
                  lines[line_index] << line
                end

                unless is_last_column
                  (max_lines - cell.size).times do |i|
                    line = lines[max_lines - i - 1] ||= ""
                    line << pad("", width)
                  end
                end
              end

              lines.each do |line|
                if indent > 0
                  line = (" " * indent) + line
                end

                io.puts line.rstrip
              end
            end

            io.string
          end

          def column_widths(table)
            max_row_length = table.map(&:size).max

            widths = [0] * max_row_length

            table.each do |row|
              row.each.with_index do |column, index|
                next unless column

                column_width = column.size
                if column_width > widths[index]
                  widths[index] = column_width
                end
              end
            end

            widths
          end

          def adjust_to_preserve_final_column_width(widths)
            adjusted_final_width = final_width(widths)

            too_small_by = min_final_column_width - adjusted_final_width

            if too_small_by > 0
              reduce_each_by = too_small_by.to_f / (widths.size - 1)
              reduce_each_by = reduce_each_by.ceil

              widths = widths.map do |width|
                width - reduce_each_by
              end

              adjusted_final_width = final_width(widths)
            end

            widths[-1] = adjusted_final_width

            widths
          end

          def final_width(widths)
            all_but_last_width = widths[0..-2].sum
            terminal_width - all_but_last_width
          end

          def terminal_width
            @terminal_width ||= begin
              config = declaration_data

              width = if config.is_a?(::Hash)
                        config[:terminal_width]
                      elsif config.respond_to?(:terminal_width)
                        # TODO: test this
                        # :nocov:
                        config.terminal_width
                        # :nocov:
                      end

              (width || IO.console_size[1]) - indent
            end
          end

          def indent
            @indent ||= if declaration_data.is_a?(::Hash)
                          declaration_data[:indent]
                        elsif declaration_data.respond_to?(:indent)
                          # TODO: test this
                          # :nocov:
                          declaration_data.indent
                          # :nocov:
                        end || 0
          end

          def min_final_column_width
            @min_final_column_width ||= begin
              config = declaration_data

              width = if config.is_a?(::Hash)
                        config[:min_final_column_width]
                      elsif config.respond_to?(:min_final_column_width)
                        # TODO: test this
                        # :nocov:
                        config.min_final_column_width
                        # :nocov:
                      end

              width || 10
            end
          end

          def pad(string, width)
            string.ljust(width + PAD_SIZE)
          end

          def cellify(table, widths)
            cellified_table = []

            row_regexes = widths.map do |width|
              /\S.{0,#{width}}\S(?=\s|$)|\S+/
            end

            table.each do |row|
              row = Util.array(row)

              cellified_table << cellified_row = []

              row.each.with_index do |column, index|
                cellified_row << cell = []

                next unless column

                width = widths[index]

                column.scan(row_regexes[index]).each do |rows_worth_of_text|
                  if rows_worth_of_text.size > width
                    parts = rows_worth_of_text.scan(/.{1,#{width - 1}}/)

                    parts_size = parts.size

                    parts.each.with_index do |rows_worth, inner_index|
                      rows_worth << "-" unless inner_index == parts_size - 1
                      cell << rows_worth
                    end
                  else
                    cell << rows_worth_of_text
                  end
                end
              end
            end

            cellified_table
          end
        end
      end
    end
  end
end
