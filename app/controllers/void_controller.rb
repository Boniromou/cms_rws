class VoidController < FundController
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
    
    respond_to do |format|
      format.js { render partial: "player_transactions/refresh_result", formats: [:js] }
    end
  end
end
