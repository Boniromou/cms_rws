class VoidController < FundController
  def create
    return unless permission_granted? PlayerTransaction.new, operation_sym

    player_transaction_id = params[:transaction_id]
    raise VoidTransactionNotExist unless player_transaction_id
    @player_transaction = PlayerTransaction.find(player_transaction_id)
    raise VoidTransactionNotExist unless @player_transaction
    @player = @player_transaction.player
    @member_id = @player.member_id

    amount = cents_to_dollar(@player_transaction.amount)
    process_transaction(amount.to_s)
  end
end
