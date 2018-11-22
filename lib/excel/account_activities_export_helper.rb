module Excel
  class AccountActivitiesExportHelper < ExportHelper
    def generate_export(data)
      @sheet = @workbook.create_worksheet name: I18n.t("export.account_activity")
      write_sheet(data)
      export
    end

    private

    def write_sheet(data)
      merge_title = [ I18n.t("general.date_time"), I18n.t("account_activity.transaction_type"), I18n.t("general.casino"), 
        I18n.t("account_activity.property"), I18n.t("account_activity.zone_location"), I18n.t("account_activity.ref_trans_id"),
        I18n.t("account_activity.round_id"), I18n.t("account_activity.slip_id"), I18n.t("account_activity.employee_name"),
        I18n.t("transaction_history.status"),I18n.t("account_activity.begin_balance"), "", I18n.t("account_activity.trans_amount"), "", I18n.t("account_activity.end_balance"), ""
      ]
      titles = [ "", "", "", "", "", "", "", "", "", "",  I18n.t("account_activity.cash"), I18n.t("account_activity.credit"),
        I18n.t("account_activity.cash"), I18n.t("account_activity.credit"), I18n.t("account_activity.cash"), I18n.t("account_activity.credit")
      ]

      @sheet.row(0).push( I18n.t("export.account_activity"))
      @sheet.row(0).default_format = @head_format
      @sheet.row(1).push( I18n.t("export.last_updated_at"), Time.now.strftime("%Y-%m-%d %H:%M:%S"))
      @sheet.row(1).default_format = @tip_format
      if data[:member_id]
        @sheet.row(3).push( I18n.t("general.member_id"), data[:member_id])
        @sheet.row(4).push( I18n.t("general.licensee"), data[:licensee_name])
        @sheet.row(5).push( I18n.t("general.date_range"), "#{format_time(data[:start_time])} ~ #{format_time(data[:end_time])} ")
        (3...5).map{|x| sheet.row(x).default_format = @tip_format }
        @current_row_number = 5
      end
      @current_row_number = @current_row_number + 3
      write_title(merge_title, @current_row_number)
      write_title(titles, @current_row_number+1)
      data[:transactions].each_with_index do |tran, index|
        current_number = @current_row_number + 2 + index
        @sheet.row(current_number).default_format = @text_format
        result_array = [
          format_time(tran['trans_date']),
          tran['trans_type'] ? tran['trans_type'].titleize : '',
          tran['casino_name'],
          tran['property_name'],
          format_zone_location(tran['machine_token']),
          tran['ref_trans_id'],
          tran['round_id'],
          tran['slip_number'],
          tran['employee_name'],
          tran['status'],
          display_balance(tran['cash_before_balance']),
          display_balance(tran['credit_before_balance']),
          display_balance(tran['cash_amt']),
          display_balance(tran['credit_amt']),
          display_balance(tran['cash_after_balance']),
          display_balance(tran['credit_after_balance'])
        ]
        @sheet.row(current_number).replace result_array
      end
      merge_cells_values = []
      (0...10).map{|i| merge_cells_values << [@current_row_number, i, @current_row_number+1, i]}
      merge_cells_values << [@current_row_number, 10, @current_row_number, 11]
      merge_cells_values << [@current_row_number, 12, @current_row_number, 13]
      merge_cells_values << [@current_row_number, 14, @current_row_number, 15]
      merge_cell(merge_cells_values)
    end

    def display_balance(amount)
      if amount
        amount = 0 if amount == 0
        number_to_currency(amount.to_f.round_down(2), negative_format: "(%u%n)").sub("$","")
      end
    end

    def format_zone_location(machine_token)
      return '' if machine_token.blank?
      infos = machine_token.split('|')
      return "#{infos[2]}/#{infos[4]}"
    end

    def format_time(time)
      begin
        unless time.blank?
          time.getlocal.strftime("%Y-%m-%d %H:%M:%S")
        end
      rescue Exception
        Time.parse(time).getlocal.strftime("%Y-%m-%d %H:%M:%S")
      end
    end

  end  
end