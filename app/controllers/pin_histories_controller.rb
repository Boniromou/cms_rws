class PinHistoriesController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include FrontMoneyHelper
  include SearchHelper
  before_filter :only => [:search, :do_search] do |controller|
    authorize_action :ChangeHistory, :pin_change_log?
  end

  def search
    @default_date = params[:accounting_date] || current_accounting_date.accounting_date
  end

  def do_search
    begin
      start_time, end_time = get_time_range_by_accounting_date(params[:start_time], params[:end_time], config_helper.pin_log_search_range)
      response = patron_requester.get_pin_audit_logs(start_time, end_time)
      @pin_histories = response.audit_logs

      unless response.success?
        Rails.logger.error "get pin audit log fail"
        @pin_histories = []
      end
    rescue Remote::NoPinAuditLog
      @pin_histories = []
    rescue FrontMoneyHelper::NoResultException => e
      @pin_histories = []
    rescue Search::OverRangeError => e
      flash[:error] = "report_search." + e.message
    rescue Search::DateTimeError => e
      flash[:error] = "transaction_history." + e.message
    rescue Remote::InvalidTimeRange
      flash[:error] = "pin_history.invalid_time_range"
    end
    respond_to do |format|
      format.html { render partial: "pin_histories/search_result", formats: [:html] }
      format.js { render partial: "pin_histories/search_result", formats: [:js] }
    end
  end
end
