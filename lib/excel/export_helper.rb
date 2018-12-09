require 'spreadsheet'

module Excel
  class ExportHelper
    include ActionView::Helpers::NumberHelper
    attr_reader :workbook, :sheet, :head_format, :tip_format, :title_format, :text_format

    def initialize
      @workbook = Spreadsheet::Workbook.new
      @head_format = Spreadsheet::Format.new :weight => :bold, :size => 14, :horizontal_align => :left, :vertical_align => :middle
      @tip_format = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :vertical_align => :middle
      @title_format = Spreadsheet::Format.new :weight => :bold, :size => 9, :horizontal_align => :center, :pattern_fg_color => :silver  , :pattern => 1,
      :vertical_align => :center
      @text_format = Spreadsheet::Format.new :size => 9, :horizontal_align => :center, :vertical_align => :center
      @current_row_number = 0
    end

    def export
      string_io = StringIO.new
      @workbook.write string_io
      string_io.string
    end

    def write_title(titles, current_row_number)
      titles.size.times do |col|
        @sheet.row(current_row_number).set_format(col, @title_format)
        @sheet.column(col).width = 20
      end
      @sheet.row(current_row_number).replace titles
    end

    def merge_cell(merge_cells_array)
      merge_cells_array.map{|arr| @sheet.merge_cells(arr[0], arr[1], arr[2], arr[3])}
    end

    def delimiter_with_precision(number, precision)
      number_with_delimiter(number_with_precision(number, precision: precision))
    end

    def boolean_to_string(boolean)
      boolean ? "Yes" : "No"
    end
  end
end