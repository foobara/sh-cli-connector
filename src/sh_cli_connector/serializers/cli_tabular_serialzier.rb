module Foobara
  module CommandConnectors
    class ShCliConnector < CommandConnector
      module Serializers
        # TODO: refactor much of this logic to Util?
        class CliTabularSerializer < CommandConnectors::Serializer
          def serialize(table)
            io = StringIO.new

            widths = column_widths(table).map { |i| i + 1 }

            widths[-1] = final_width(widths)

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
                    lines[max_lines - i - 1] << pad("", width)
                  end
                end
              end

              lines.each do |line|
                io.puts line
              end
            end

            io.string
          end

          def column_widths(table)
            widths = []

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

          def final_width(widths)
            max_total_width = terminal_width

            all_but_last_width = widths[0..-2].sum
            terminal_width - all_but_last_width
          end

          def terminal_width
            IO.console.winsize[1]
          end

          def pad(string, width)
            string.ljust(width)
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
                    parts = rows_worth_of_text.scan(".{#{width - 1}}")

                    parts_size = parts.size

                    parts.each.with_index do |rows_worth, index|
                      rows_worth << "-" if index == parts_size - 1
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
