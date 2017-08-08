class VoidController < FundController
  rescue_from FundInOut::AlreadyVoided, :with => :handle_already_voided
  rescue_from FundInOut::VoidTransactionNotExist, :with => :handle_transaction_not_exist
  rescue_from FundInOut::InvalidMachineToken, :with => :handle_invalid_machine_token

  def create
    super
    flash[:success] = {key: "void_transaction.success", replace: {:slip_number => @target_transaction.slip_number}}
    
    respond_to do |format|
      format.js { render partial: "player_transactions/refresh_result", formats: [:js] }
    end
  end

  def extract_params
    player_transaction_id = params[:transaction_id]
    raise FundInOut::VoidTransactionNotExist unless player_transaction_id
    @target_transaction = PlayerTransaction.find_by_id_and_casino_id(player_transaction_id, current_casino_id)
    raise FundInOut::InvalidMachineToken unless @target_transaction
    @player = @target_transaction.player
    @server_amount = @target_transaction.amount
    @amount = cents_to_dollar(@server_amount)
    @ref_trans_id = @target_transaction.ref_trans_id
    @data = nil
  end

  def check_transaction_acceptable
    raise FundInOut::AlreadyVoided if @target_transaction.voided?
  end

  def handle_call_wallet_fail(e)
    @player.lock_account!('pending')
    handle_fund_error('flash_message.contact_service')
  end

  def handle_balance_not_enough(e)
    @transaction.rejected!
    handle_fund_error({ key: "invalid_amt.no_enough_to_void_deposit", replace: { balance: to_formatted_display_amount_str(e.message.to_f)} })
  end

  def handle_transaction_not_exist(e)
    handle_fund_error('void_transaction.not_exist')
  end

  def handle_invalid_machine_token(e)
    handle_fund_error('void_transaction.invalid_machine_token')
  end

  def handle_already_voided(e)
    handle_fund_error({ key: "void_transaction.already_void", replace: { slip_number: @target_transaction.slip_number} })
  end
  
  def handle_fund_error(msg)
    flash[:fail] = msg
    respond_to do |format|
      format.js { render partial: "player_transactions/refresh_result", formats: [:js] }
    end
  end
end
