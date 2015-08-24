class PlayerTransactionsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include PlayerTransactionsHelper

  def search
    return unless permission_granted? PlayerTransaction.new
    @card_id = params[:card_id]
  end

  def do_search
    return unless permission_granted? PlayerTransaction.new, :search?
        
    begin
    @start_time = parse_datetime(params[:start_time], today_start_time)
    @end_time = parse_datetime(params[:end_time], today_end_time)
      
    id_type = params[:id_type]
    id_number = params[:id_number]
    
    transaction_id = params[:transaction_id]
    selected_tab_index = params[:selected_tab_index]
    @player_transactions = PlayerTransaction.search_query(id_type, id_number, @start_time, @end_time, transaction_id, selected_tab_index)
       
    rescue SearchPlayerTransaction::OverRangeError => e
      flash[:error] = "report_search." + e.message
    rescue SearchPlayerTransaction::DateTimeError => e
      flash[:error] = "report_search." + e.message
    rescue ArgumentError 
      flash[:error] = "report_search.datetime_format_not_valid"
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
    @operation =  @transaction.action_type_str
  end
  
  def get_start_time(time_str)
    start_time = parse_datetime(time_str, today_start_time)
    start_time = today_start_time if today_start_time - 30*24*60*60 > start_time
    start_time
  end
end
