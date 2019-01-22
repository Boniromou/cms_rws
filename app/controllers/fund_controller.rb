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
  rescue_from FundInOut::InvalidMachineToken, :with => :handle_invalid_machine_token
 
  def operation_sym
    (action_str + '?').to_sym
  end

  def action_str
    self.class.name.gsub("Controller","").underscore
  end

  def new
    @member_id = params[:member_id]
    @action = action_str
    @player = policy_scope(Player).find_by_member_id(@member_id)
    @casino_id = current_casino_id
    authorize_action @player, :non_test_mode?
    @exception_transaction = params[:exception_transaction]
  end

  def create
    @exception_transaction = params[:exception_transaction]
    extract_params
    check_transaction_acceptable
    execute_transaction
    if @exception_transaction == 'yes' && (action_str == 'deposit' || action_str == 'withdraw')
      flash[:success] = {key: "flash_message.manual_#{action_str}_complete", replace: {amount: to_display_amount_str(@transaction.amount)}}
      redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
    else
      flash[:success] = {key: "flash_message.#{action_str}_complete", replace: {amount: to_display_amount_str(@transaction.amount)}}
    end
  end
  
  protected

  def extract_params
    member_id = params[:player][:member_id]
    @player = policy_scope(Player).find_by_member_id(member_id)
    @amount = params[:player_transaction][:amount]
    validate_amount_str(@amount)
    @server_amount = to_server_amount(@amount)
    @ref_trans_id = nil
    @data = {:remark => "#{params[:player_transaction][:remark]}"}
    @payment_method_type = params[:payment_method_type]
    @source_of_funds = params[:source_of_funds]
  end

  def check_transaction_acceptable
    authorize_action @player, :non_test_mode?
    raise FundInOut::PlayerLocked if @player.account_locked?
  end

  def validate_pin
    pin = params[:player_transaction][:pin]
    result = requester_helper.validate_pin(@player.member_id, pin)
    raise Request::InvalidPin unless result
  end

  def execute_transaction
    if @exception_transaction == 'yes'
      AuditLog.player_log(action_str, current_user.name, client_ip, sid,:description => {:location => get_location_info, :shift => current_shift.name}) do
      @transaction = create_player_transaction(@player.member_id, @server_amount, @ref_trans_id, @data.to_yaml)
      puts Approval::Request::PENDING
      response = Approval::Models.submit('player_transaction', @transaction.id, 'exception_transaction', get_submit_data, @current_user.name)
      end
    else
      AuditLog.player_log(action_str, current_user.name, client_ip, sid,:description => {:location => get_location_info, :shift => current_shift.name}) do
      @transaction = create_player_transaction(@player.member_id, @server_amount, @ref_trans_id, @data.to_yaml)
      response = call_wallet(@player.member_id, @amount, @transaction.ref_trans_id, @transaction.trans_date.localtime, @transaction.source_type, @transaction.machine_token    )
      handle_wallet_result(@transaction, response)
      end
    end  
  end

  def get_submit_data
    {    
      :casino_id => Casino.find_by_id(@transaction.casino_id).name,
      :player_id => @player.member_id,
      :amount_in_cent => @transaction.amount,
      :amount => @transaction.amount / 100.0,
      :transaction_type => TransactionType.find_by_id(@transaction.transaction_type_id).name.gsub('_',' ').titleize,
      :payment_method => PaymentMethod.find_by_id(@transaction.payment_method_id).name,
      :source_of_fund => SourceOfFund.find_by_id(@transaction.source_of_fund_id).name
    }
  end 

  def create_player_transaction(member_id, amount, ref_trans_id = nil, data = nil)
    raise FundInOut::InvalidMachineToken unless current_machine_token
    if @exception_transaction == 'yes'
      PlayerTransaction.send "save_exception_#{action_str}_transaction", member_id, amount, current_shift.id, current_user.id, current_machine_token, ref_trans_id, data, @payment_method_type, @source_of_funds
    else
      PlayerTransaction.send "save_#{action_str}_transaction", member_id, amount, current_shift.id, current_user.id, current_machine_token, ref_trans_id, data, @payment_method_type, @source_of_funds
    end    
  end

  def handle_wallet_result(transaction, response)
    if !response.success?
      raise FundInOut::CallWalletFail
    else
      PlayerTransaction.transaction do
        transaction.trans_date = response.trans_date
        transaction.completed!
      end
    end
  end
  
  def handle_player_locked(e)
    handle_fund_error("player_status.is_locked")
  end


  def handle_amount_invalid_error(e)
    handle_fund_error("invalid_amt." + action_str)
  end

  def handle_call_wallet_fail(e)
    @player.lock_account!('pending')
    flash[:fail] = 'flash_message.contact_service'
    redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end

  def handle_fund_error(msg)
    flash[:fail] = msg
    redirect_to :action => 'new', member_id: @player.member_id, exception_transaction: @exception_transaction
  end

  def handle_balance_not_enough(e)
    @transaction.rejected!
    handle_fund_error({ key: "invalid_amt.no_enough_to_#{action_str}", replace: { balance: to_formatted_display_amount_str(e.result.to_f)} })
  end

  def handle_pin_error
    flash[:fail] = 'invalid_pin.invalid_pin'
    redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end

  def handle_call_patron_fail
    flash[:fail] = 'flash_message.contact_service'
    redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end

  def handle_credit_exist
    @transaction.rejected!
    flash[:fail] = 'invalid_amt.credit_exist'
    redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end

  def handle_credit_not_match(e)
    @transaction.rejected!
    flash[:fail] = { key: "invalid_amt.no_enough_to_credit_expire", replace: { balance: to_formatted_display_amount_str(e.result.to_f)} }
    redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end

  def handle_invalid_machine_token(e)
    handle_fund_error('void_transaction.invalid_machine_token')
  end

end
