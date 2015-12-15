class FundController < ApplicationController
  include FundHelper

  layout 'cage'
  before_filter :only => [:new, :create] do |controller|
    authorize_action :PlayerTransaction, operation_sym
  end
  rescue_from Remote::CallWalletError, :with => :handle_call_wallet_fail
  rescue_from Remote::AmountNotEnough, :with => :handle_balance_not_enough
  rescue_from Remote::CreditNotExpired, :with => :handle_credit_exist
  rescue_from FundInOut::AmountInvalidError, :with => :handle_amount_invalid_error
  rescue_from FundInOut::CallWalletFail, :with => :handle_call_wallet_fail
  rescue_from Request::InvalidPin, :with => :handle_pin_error
  rescue_from Remote::CallPatronFail, :with => :handle_call_patron_fail
  rescue_from Remote::AmountNotMatch, :with => :handle_credit_not_match
  rescue_from FundInOut::PlayerLocked, :with => :handle_player_locked

  def operation_sym
    (action_str + '?').to_sym
  end

  def action_str
    self.class.name.gsub("Controller","").underscore
  end

  def new
    @member_id = params[:member_id]
    @action = action_str
    @player = Player.find_by_member_id(@member_id)
  end

  def create
    extract_params
    check_transaction_acceptable
    execute_transaction
    flash[:success] = {key: "flash_message.#{action_str}_complete", replace: {amount: to_display_amount_str(@transaction.amount)}}
  end
  
  protected

  def extract_params
    member_id = params[:player][:member_id]
    @player = policy_scope(Player).find_by_member_id(member_id)
    @amount = params[:player_transaction][:amount]
    validate_amount_str(@amount)
    @server_amount = to_server_amount(@amount)
    @ref_trans_id = nil
    @data = {:remark => params[:player_transaction][:remark]}.to_yaml
  end

  def check_transaction_acceptable
    raise FundInOut::PlayerLocked if @player.account_locked?
  end

  def validate_pin
    pin = params[:player_transaction][:pin]
    response = requester_helper.validate_pin(@player.member_id, pin)
    raise Request::InvalidPin.new unless response
  end

  def execute_transaction
    AuditLog.player_log(action_str, current_user.name, client_ip, sid,:description => {:location => get_location_info, :shift => current_shift.name}) do
      @transaction = create_player_transaction(@player.member_id, @server_amount, @ref_trans_id, @data)
      result = call_wallet(@player.member_id, @amount, @transaction.ref_trans_id, @transaction.trans_date.localtime)
      handle_wallet_result(@transaction, result)
    end
  end

  def create_player_transaction(member_id, amount, ref_trans_id = nil, data = nil)
    PlayerTransaction.send "save_#{action_str}_transaction", member_id, amount, current_shift.id, current_user.id, current_machine_token, ref_trans_id, data
  end

  def handle_wallet_result(transaction, result)
    return transaction.completed! if result == 'OK'
    raise FundInOut::CallWalletFail
  end
  
  def handle_player_locked(e)
    handle_fund_error("player_status.is_locked")
  end


  def handle_amount_invalid_error(e)
    handle_fund_error("invalid_amt." + action_str)
  end

  def handle_call_wallet_fail(e)
    @player.lock_account!('pending')
    flash[:alert] = 'flash_message.contact_service'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end

  def handle_fund_error(msg)
    flash[:alert] = msg
    flash[:fade_in] = false
    redirect_to :action => 'new', member_id: @player.member_id
  end

  def handle_balance_not_enough(e)
    @transaction.rejected!
    handle_fund_error({ key: "invalid_amt.no_enough_to_#{action_str}", replace: { balance: to_formatted_display_amount_str(e.result.to_f)} })
  end

  def handle_pin_error
    flash[:alert] = 'invalid_pin.invalid_pin'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end

  def handle_call_patron_fail
    flash[:alert] = 'flash_message.contact_service'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end

  def handle_credit_exist
    @transaction.rejected!
    flash[:alert] = 'invalid_amt.credit_exist'
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end

  def handle_credit_not_match(e)
    @transaction.rejected!
    flash[:alert] = { key: "invalid_amt.no_enough_to_credit_expire", replace: { balance: to_formatted_display_amount_str(e.result.to_f)} }
    flash[:fade_in] = false
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end
end
