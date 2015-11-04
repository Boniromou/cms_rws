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
    accounting_date = params[:accounting_date]
    @accounting_date = parse_date(accounting_date, current_accounting_date.accounting_date)
    # shift_name = params[:shift_name]
    # shift_type_id = ShiftType.get_id_by_name(shift_name)
    accounting_date_id = AccountingDate.get_id_by_date(@accounting_date)
    # shift = Shift.find_by_accounting_date_id_and_shift_type_id(accounting_date_id, shift_type_id)
    start_shift = Shift.where(:accounting_date_id => accounting_date_id).order(:created_at).first
    end_shift = Shift.where(:accounting_date_id => accounting_date_id).order(:created_at).last
    raise FrontMoneyHelper::NoResultException.new "shift not found" if start_shift.nil? || end_shift.nil?

    @player_transaction_group = PlayerTransaction.search_transactions_group_by_station(start_shift.id, current_user.id, end_shift.id)
    rescue FrontMoneyHelper::NoResultException => e
      @player_transaction_group = []
    end
    respond_to do |format|
      format.html { render partial: "front_money/search_result", formats: [:html] }
      format.js { render partial: "front_money/search_result", formats: [:js] }
    end
  end
end
