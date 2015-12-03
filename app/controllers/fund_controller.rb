class FundController < ApplicationController
  include FundHelper

  layout 'cage'
  rescue_from Remote::AmountNotEnough, :with => :handle_balance_not_enough
  rescue_from Remote::CreditNotExpired, :with => :handle_credit_exist
  rescue_from FundInOut::AmountInvalidError, :with => :handle_amount_invalid_error
  rescue_from FundInOut::CallWalletFail, :with => :handle_call_wallet_fail
  rescue_from Request::InvalidPin, :with => :handle_pin_error
  rescue_from Remote::CallPatronFail, :with => :handle_call_patron_fail
  rescue_from Remote::AmountNotMatch, :with => :handle_credit_not_match

  def operation_sym
    (action_str + '?').to_sym
  end

  def action_str
    self.class.name.gsub("Controller","").underscore
  end

  def new
    return unless permission_granted? :PlayerTransaction, operation_sym

    @member_id = params[:member_id]
    @action = action_str
    @player = Player.find_by_member_id(@member_id)
  end

  def create
    return unless permission_granted? :PlayerTransaction, operation_sym

    @member_id = params[:player][:member_id]
    @player = Player.find_by_member_id(@member_id)
    if @player.account_locked?
      handle_fund_error("player_status.is_locked")
      return
    end
    amount = params[:player_transaction][:amount]
    pin = params[:player_transaction][:pin]
    data = {:remark => params[:player_transaction][:remark]}.to_yaml
    if action_str == 'withdraw'
      response = PlayerInfo.validate_pin(@member_id, pin)
      raise Request::InvalidPin.new unless response
    end
    server_amount = get_server_amount(amount)
    AuditLog.fund_in_out_log(action_str, current_user.name, client_ip, sid,:description => {:location => get_location_info, :shift => current_shift.name}) do
      @transaction = do_fund_action(@member_id, server_amount, nil, data)
      result = call_wallet(@member_id, amount, @transaction.ref_trans_id, @transaction.trans_date.localtime)
      handle_wallet_result(@transaction, result)
    end
    flash[:success] = {key: "flash_message.#{action_str}_complete", replace: {amount: to_display_amount_str(@transaction.amount)}}
    redirect_to balance_path + "?member_id=#{@member_id}" if action_str == 'credit_expire' || action_str == 'credit_deposit' 
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

  def handle_balance_not_enough(e)
    @transaction.rejected!
    handle_fund_error({ key: "invalid_amt.no_enough_to_#{action_str}", replace: { balance: to_formatted_display_amount_str(e.result.to_f)} })
  end

  def handle_pin_error
    flash[:alert] = 'invalid_pin.invalid_pin'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@member_id}"
  end

  def handle_call_patron_fail
    flash[:alert] = 'flash_message.contact_service'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@member_id}"
  end

  def handle_credit_exist
    @transaction.rejected!
    flash[:alert] = 'invalid_amt.credit_exist'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@member_id}"
  end

  def handle_credit_not_match(e)
    @transaction.rejected!
    flash[:alert] = { key: "invalid_amt.no_enough_to_credit_expire", replace: { balance: to_formatted_display_amount_str(e.result.to_f)} }
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@member_id}"
  end

  protected

  def do_fund_action(member_id, amount, ref_trans_id = nil, data = nil)
    PlayerTransaction.send "save_#{action_str}_transaction", member_id, amount, current_shift.id, current_user.id, current_machine_token, ref_trans_id, data
  end

  def handle_wallet_result(transaction, result)
    return transaction.completed! if result == 'OK'
    raise FundInOut::CallWalletFail
  end
end
