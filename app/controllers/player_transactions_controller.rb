class PlayerTransactionsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper
  include PlayerTransactionsHelper
  include SearchHelper
  before_filter :authorize_action, :only => [:search, :do_search, :print, :reprint]

  def search
    @card_id = params[:card_id]
    @default_date = params[:accounting_date] || current_accounting_date.accounting_date
    @operation = params[:operation]
  end

  def do_search
        
    begin
    @operation = params[:operation]

    id_type = params[:id_type]
    id_number = params[:id_number]

    selected_tab_index = params[:selected_tab_index]
    slip_number = params[:slip_number]
    search_range = config_helper.trans_history_search_range
    if selected_tab_index == '0'
      shifts = get_shifts(params[:start_time], params[:end_time], id_number, @operation, search_range)
      requester_helper.update_player(id_type,id_number) unless id_number.blank?
      @player_transactions = policy_scope(PlayerTransaction).search_query(id_type, id_number, shifts[0].id, shifts[1].id, nil, selected_tab_index, @operation)
    else
      @player_transactions = policy_scope(PlayerTransaction).search_query(nil, nil, nil, nil, slip_number, selected_tab_index)
    end
    rescue Remote::PlayerNotFound => e
      @player_transactions = []
    rescue Search::NoResultException => e
      @player_transactions = []
    rescue SearchPlayerTransaction::NoIdNumberError => e
      flash[:error] = "transaction_history." + e.message
    rescue Search::OverRangeError => e
      flash[:error] = { key: "report_search." + e.message, replace: {day: search_range}}
    rescue Search::DateTimeError => e
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
    AuditLog.player_transaction_log("print", current_user.name, client_ip, sid,:description => {:location => get_location_info, :shift => current_shift.name}) do
    end
    member_id = params[:member_id]
    redirect_to balance_path + "?member_id=#{member_id}"
  end

  def reprint
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
