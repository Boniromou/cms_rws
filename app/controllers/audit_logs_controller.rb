class AuditLogsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper

  def search
    @action_lists = AuditLog::ACTION_MENU
  end

  def do_search
    start_time = parse_date(params[:start_time], current_accounting_date.accounting_date)
    end_time = parse_date(params[:end_time], current_accounting_date.accounting_date)
    action_by = params[:action_by] unless params[:action_by].blank?
    action_type = params[:action_type] unless params[:action_type].blank?
    audit_target = params[:target_name] unless params[:target_name].blank? || params[:target_name] == "all"
    action = params[:action_list] unless params[:action_list].blank? || params[:action_list] == "all"
    @audit_logs = AuditLog.search_query(audit_target, action, action_type, action_by, start_time, end_time)
    
    respond_to do |format|
      format.html { render partial: "audit_logs/search_result", formats: [:html] }
      format.js { render partial: "audit_logs/search_result", formats: [:js] }
    end
  
  end
end
