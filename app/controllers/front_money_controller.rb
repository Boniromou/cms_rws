class FrontMoneyController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include FrontMoneyHelper

  def search
    return unless permission_granted? :Shift, :search_fm?
    @shift_name_list = ["morning","swing","night"]
    @accounting_date = params[:accounting_date] || current_accounting_date.accounting_date
    @shift_name = params[:shift_name] || "morning"
  end

  def do_search
    return unless permission_granted? :Shift, :search_fm?
    begin
      accounting_date = parse_date(params[:accounting_date], current_accounting_date.accounting_date)
      @accounting_date = AccountingDate.get_by_date(accounting_date)
      start_shift = @accounting_date.shifts.first
      end_shift = @accounting_date.shifts.last
      raise FrontMoneyHelper::NoResultException.new "shift not found" if start_shift.nil? || end_shift.nil?
      @player_transactions = PlayerTransaction.search_transactions_by_user_and_shift(current_user.id, start_shift.id, end_shift.id)
    rescue FrontMoneyHelper::NoResultException => e
      @player_transactions = []
    end
    respond_to do |format|
      format.html { render partial: "front_money/search_result", formats: [:html] }
      format.js { render partial: "front_money/search_result", formats: [:js] }
    end
  end
end
