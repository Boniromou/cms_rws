module Excel
  class ApprovalExportHelper < ExportHelper
    def generate_export(record)
      @sheet = @workbook.create_worksheet name: I18n.t("export.approved_merge")
      write_sheet(record)
      export
    end
    
    def generate_reject_export(record)
      @sheet = @workbook.create_worksheet name: I18n.t("export.rejected_merge")
      write_reject_sheet(record)
      export
    end 
    
    private
    def write_reject_sheet(record)
      @sheet.row(0).push( I18n.t("export.rejected_merge"))
      @sheet.row(0).default_format = @head_format
      @sheet.row(1).push( I18n.t("export.last_updated_at"), Time.now.strftime("%Y-%m-%d %H:%M:%S"))
      @sheet.row(1).default_format = @tip_format

      @current_row_number = 3
      titles = [I18n.t("merge_approval.licensee_id"), I18n.t("merge_approval.vic_member"), I18n.t("merge_approval.before_amount"), I18n.t("merge_approval.amount"), I18n.t("merge_approval.after_amount"), I18n.t("merge_approval.sur_member"), I18n.t("merge_approval.before_amount"), I18n.t("merge_approval.amount"), I18n.t("merge_approval.after_amount"), I18n.t("merge_approval.status"), I18n.t("merge_approval.rejected_by"), I18n.t("merge_approval.updated_at")]
      write_title(titles, @current_row_number)

      record.each_with_index do |record, index|
        current_number = @current_row_number + 1 + index
        @sheet.row(current_number).default_format = @text_format
        result_array = [
         record[:licensee_id],
         record[:player_vic_id],
         record[:player_vic_before_amount],
         record[:amount],
         record[:player_vic_after_amount],
         record[:player_sur_id],
         record[:player_sur_before_amount],
         record[:amount],
         record[:player_sur_after_amount],
         'Reject',
         record[:cancel_by],
         record[:cancel_at]
        ]
        @sheet.row(current_number).replace result_array
      end 
    end
 
    def write_sheet(record)
      @sheet.row(0).push( I18n.t("export.approved_merge"))
      @sheet.row(0).default_format = @head_format
      @sheet.row(1).push( I18n.t("export.last_updated_at"), Time.now.strftime("%Y-%m-%d %H:%M:%S"))
      @sheet.row(1).default_format = @tip_format
      
      @current_row_number = 3
      titles = [I18n.t("merge_approval.licensee_id"), I18n.t("merge_approval.vic_member"), I18n.t("merge_approval.before_amount"), I18n.t("merge_approval.amount"), I18n.t("merge_approval.after_amount"), I18n.t("merge_approval.sur_member"), I18n.t("merge_approval.before_amount"), I18n.t("merge_approval.amount"), I18n.t("merge_approval.after_amount"), I18n.t("merge_approval.submitted_by"), I18n.t("merge_approval.updated_at"), I18n.t("merge_approval.transaction_status")]
      write_title(titles, @current_row_number)
      
      record.each_with_index do |record, index|
        current_number = @current_row_number + 1 + index
        @sheet.row(current_number).default_format = @text_format
        result_array = [
         record[:licensee_id],
         record[:player_vic_id],
         record[:player_vic_before_amount],
         record[:amount],
         record[:player_vic_after_amount],
         record[:player_sur_id],
         record[:player_sur_before_amount],
         record[:amount],
         record[:player_sur_after_amount],
         record[:submit_by],
         record[:approve_at],
         'completed'
        ]
        @sheet.row(current_number).replace result_array
      end
    end


  end
end
