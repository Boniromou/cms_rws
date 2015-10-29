class VoidController < FundController
  rescue_from FundInOut::AlreadyVoided, :with => :handle_already_voided

  def create
    return unless permission_granted? PlayerTransaction.new, operation_sym

    player_transaction_id = params[:transaction_id]
    raise FundInOut::VoidTransactionNotExist unless player_transaction_id
    @target_transaction = PlayerTransaction.find(player_transaction_id)
    raise FundInOut::VoidTransactionNotExist unless @target_transaction
    raise FundInOut::AlreadyVoided if @target_transaction.voided?
    @player = @target_transaction.player
    @member_id = @player.member_id

    server_amount = @target_transaction.amount
    amount = cents_to_dollar(server_amount)
    AuditLog.fund_in_out_log(action_str, current_user.name, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
      @transaction = do_fund_action(@member_id, server_amount, @target_transaction.ref_trans_id)
      result = call_wallet(@member_id, amount, @transaction.ref_trans_id, @transaction.trans_date.localtime, current_shift.id, current_station_id, current_user.id)
      handle_wallet_result(@transaction, result)
    end

    flash[:success] = {key: "void_transaction.success", replace: {:slip_number => @target_transaction.slip_number}}
    @operation =  @transaction.transaction_type.name
    
    respond_to do |format|
      format.js { render partial: "player_transactions/refresh_result", formats: [:js] }
    end
  end
  
  def handle_call_wallet_fail(e)
    @player.lock_account!('pending')
    handle_fund_error('flash_message.contact_service')
  end

  def handle_balance_not_enough(e)
    @transaction.rejected!
    handle_fund_error({ key: "invalid_amt.no_enough_to_void_deposit", replace: { balance: to_formatted_display_amount_str(e.message.to_f)} })
  end

  def handle_already_voided(e)
    handle_fund_error({ key: "void_transaction.already_void", replace: { slip_number: @target_transaction.slip_number} })
  end
  
  def handle_fund_error(msg)
    flash[:alert] = msg
    flash[:fade_in] = false
    respond_to do |format|
      format.js { render partial: "player_transactions/refresh_result", formats: [:js] }
    end
  end
end
