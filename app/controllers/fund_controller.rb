class FundController < ApplicationController
  include FundHelper

  layout 'cage'
  rescue_from FundInOut::AmountInvalidError, :with => :handle_amount_invalid_error
  rescue_from FundInOut::CallWalletFail, :with => :handle_call_wallet_fail

  def operation_sym
    raise NotImplementedError
  end

  def operation_str
    raise NotImplementedError
  end

  def action_str
    raise NotImplementedError
  end

  def new
    return unless permission_granted? PlayerTransaction.new, operation_sym

    member_id = params[:member_id]
    @operation = operation_str
    @player = Player.find_by_member_id(member_id)
  end

  def create
    return unless permission_granted? PlayerTransaction.new, operation_sym

    @member_id = params[:player][:member_id]
    @player = Player.find_by_member_id(@member_id)

    if @player.account_locked?
      handle_fund_error("player_status.is_locked")
      return
    end

    amount = params[:player_transaction][:amount]
    server_amount = get_server_amount(amount)
    AuditLog.fund_in_out_log(action_str, current_user.name, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
      @transaction = do_fund_action(@member_id, server_amount)
      result = call_wallet(@member_id, amount, make_trans_id(@transaction.id), @transaction.trans_date.localtime, current_shift.id, current_station_id, current_user.id)
      handle_wallet_result(@transaction, result)
    end
  end

  def get_server_amount(amount)
    validate_amount_str(amount)
    to_server_amount(amount)
  end

  def handle_amount_invalid_error(e)
    handle_fund_error("invalid_amt." + action_str)
  end

  def handle_call_wallet_fail(e)
    @player.lock_account!('pending')
    flash[:alert] = 'flash_message.contact_service'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@member_id}"
  end

  def handle_fund_error(msg)
    flash[:alert] = msg
    flash[:fade_in] = false
    redirect_to :action => 'new', member_id: @member_id
  end

  protected

  def do_fund_action(member_id, amount)
    PlayerTransaction.send "save_#{operation_str}_transaction", member_id, amount, current_shift.id, current_user.id, current_station_id
  end

  def handle_wallet_result(transaction, result)
    return transaction.completed! if result == 'OK'
    raise FundInOut::CallWalletFail
  end
end
