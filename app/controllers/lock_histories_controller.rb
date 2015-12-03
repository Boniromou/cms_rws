class LockHistoriesController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include FrontMoneyHelper

  def search
    return unless permission_granted? :ChangeHistory, :lock_player_log?

    @accounting_date = params[:accounting_date] || current_accounting_date.accounting_date
    respond_to do |format|
      format.html { render "lock_histories/search", formats: [:html] }
      format.js { render "lock_histories/search", formats: [:js] }
    end
  end

  def do_search
    return unless permission_granted? :ChangeHistory, :lock_player_log?
    
    begin
    accounting_date = params[:accounting_date]
    @accounting_date = parse_date(accounting_date, current_accounting_date.accounting_date)
    accounting_date_id = AccountingDate.get_by_date(@accounting_date).id
    start_time = Shift.where(:accounting_date_id => accounting_date_id).order(:created_at).first.created_at
    end_time = Shift.where(:accounting_date_id => accounting_date_id).order(:created_at).last.roll_shift_at
    start_time = Time.now.utc unless start_time
    end_time = Time.now.utc unless end_time

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
