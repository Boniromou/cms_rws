class LockHistoriesController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include FrontMoneyHelper
  include SearchHelper

  def search
    return unless permission_granted? :ChangeHistory, :lock_player_log?

    @default_date = params[:accounting_date] || current_accounting_date.accounting_date
  end

  def do_search
    return unless permission_granted? :ChangeHistory, :lock_player_log?
    
    begin
    start_time, end_time = get_time_range_by_accounting_date(params[:start_time], params[:end_time], config_helper.change_log_search_range)
    
    @lock_histories = ChangeHistory.by_property_id(current_user.property_id).since(start_time).until(end_time).where('action=? OR action=?', 'lock', 'unlock')
    rescue FrontMoneyHelper::NoResultException => e
      @lock_histories = []
    end
    respond_to do |format|
      format.html { render partial: "lock_histories/search_result", formats: [:html] }
      format.js { render partial: "lock_histories/search_result", formats: [:js] }
    end
  end
end
