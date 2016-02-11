class AuditLogsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  before_filter :only => [:search, :do_search] do |controller|
    authorize_action :AuditLog, :search_audit_log?
  end

  def search
    @default_date = Time.now.strftime("%Y-%m-%d")
  end

  def do_search
    begin
      start_time = parse_search_time(params[:start_time]) unless params[:start_time].blank?
      end_time = parse_search_time(params[:end_time], true) unless params[:end_time].blank?
      date_gap = end_time - start_time
      search_range = config_helper.audit_log_search_range
      raise Search::OverRangeError, "limit_remark" if date_gap > search_range * 24 * 3600
      action_by = params[:action_by] unless params[:action_by].blank?
      action_type = params[:action_type] unless params[:action_type].blank?
      audit_target = params[:target_name] unless params[:target_name].blank? || params[:target_name] == "all"
      action = params[:action_list] unless params[:action_list].blank? || params[:action_list] == "all"
      @audit_logs = AuditLog.search_query(audit_target, action, action_type, action_by, start_time, end_time)
    rescue Search::NoResultException => e
      @audit_logs = []
    rescue Search::OverRangeError => e
      flash[:error] = { key: "report_search." + e.message, replace: {day: search_range}}
    rescue Search::DateTimeError => e
      flash[:error] = "transaction_history." + e.message
    rescue ArgumentError 
      flash[:error] = "transaction_history.datetime_format_not_valid"
    end
    
    respond_to do |format|
      format.html { render partial: "audit_logs/search_result", formats: [:html] }
      format.js { render partial: "audit_logs/search_result", formats: [:js] }
    end
  end
end
