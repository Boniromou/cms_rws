class LockHistoriesController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include SearchHelper
  before_filter :only => [:search, :do_search] do |controller|
    authorize_action :ChangeHistory, :lock_player_log?
  end

  def search
    @default_date = params[:accounting_date] || current_accounting_date.accounting_date
  end

  def do_search
    begin
      search_range = config_helper.change_log_search_range
      start_time, end_time = get_time_range_by_accounting_date(params[:start_time], params[:end_time], search_range)
      @lock_histories = policy_scope(ChangeHistory.since(start_time).until(end_time).where('action=? OR action=?', 'lock', 'unlock'))
    rescue Search::NoResultException => e
      @lock_histories = []
    rescue Search::OverRangeError => e
      flash[:error] = { key: "report_search." + e.message, replace: {day: search_range}}
    rescue Search::DateTimeError => e
      flash[:error] = "transaction_history." + e.message
    rescue ArgumentError 
      flash[:error] = "transaction_history.datetime_format_not_valid"
    end
    respond_to do |format|
      format.html { render partial: "lock_histories/search_result", formats: [:html] }
      format.js { render partial: "lock_histories/search_result", formats: [:js] }
    end
  end
end
