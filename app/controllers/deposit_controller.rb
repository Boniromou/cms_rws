class DepositController < FundController
  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.deposit(member_id, amount, ref_trans_id, trans_date)
  end
  
  def extract_params
    super
    @is_player_deposit = !params[:player_transaction][:non_player_deposit]
    @deposit_reason = params[:player_transaction][:deposit_reason]
    @data[:is_player_deposit] = @is_player_deposit
    @data[:deposit_reason] = @deposit_reason
  end
end
