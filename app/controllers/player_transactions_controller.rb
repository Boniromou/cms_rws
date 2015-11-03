class PlayerTransactionsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include PlayerTransactionsHelper

  def search
    return unless permission_granted? PlayerTransaction.new
    @card_id = params[:card_id]
    @default_date = params[:accounting_date] || current_accounting_date.accounting_date
  end

  def do_search
    return unless permission_granted? PlayerTransaction.new, :search?
        
    begin
    @start_time = parse_search_time(params[:start_time])
    @end_time = parse_search_time(params[:end_time], true) 

    id_type = params[:id_type]
    id_number = params[:id_number]

    selected_tab_index = params[:selected_tab_index]
    slip_number = params[:slip_number]
    if selected_tab_index == '0'
      shifts = get_start_and_end_shifts(@start_time, @end_time, id_number)
      PlayerInfo.update(id_type,id_number)
      @player_transactions = PlayerTransaction.search_query(id_type, id_number, shifts[0].id, shifts[1].id, nil, selected_tab_index)
    else
      @player_transactions = PlayerTransaction.search_query(nil, nil, nil, nil, slip_number, selected_tab_index)
    end
    rescue SearchPlayerTransaction::NoResultException => e
      @player_transactions = []
    rescue SearchPlayerTransaction::NoIdNumberError => e
      flash[:error] = "transaction_history." + e.message
    rescue SearchPlayerTransaction::OverRangeError => e
      flash[:error] = "report_search." + e.message
    rescue SearchPlayerTransaction::DateTimeError => e
      flash[:error] = "transaction_history." + e.message
    rescue ArgumentError 
      flash[:error] = "transaction_history.datetime_format_not_valid"
    end

    respond_to do |format|
      format.html { render partial: "player_transactions/search_result", formats: [:html] }
      format.js { render partial: "player_transactions/search_result", formats: [:js] }
    end

  end

  def print
    return unless permission_granted? PlayerTransaction.new
    AuditLog.print_log("print", current_user.name, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
    end
    member_id = params[:member_id]
    redirect_to balance_path + "?member_id=#{member_id}"
  end

  def reprint
    return unless permission_granted? PlayerTransaction.new
    transaction_id = params[:transaction_id]
    @transaction = PlayerTransaction.find(transaction_id)
    @player = Player.find(@transaction.player_id)
    @operation =  @transaction.transaction_type.name
  end
  
  def get_start_time(time_str)
    start_time = parse_datetime(time_str, today_start_time)
    start_time = today_start_time if today_start_time - 30*24*60*60 > start_time
    start_time
  end
end
