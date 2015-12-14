class AuditLogsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper

  def search
    return unless permission_granted? :AuditLog, :search_audit_log?

    @default_date = Time.now.strftime("%Y-%m-%d")
  end

  def do_search
    return unless permission_granted? :AuditLog, :search_audit_log?

    start_time = parse_search_time(params[:start_time]) unless params[:start_time].blank?
    end_time = parse_search_time(params[:end_time], true) unless params[:end_time].blank?
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
