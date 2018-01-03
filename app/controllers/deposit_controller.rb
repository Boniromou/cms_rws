class DepositController < FundController
  def new
    super
    @casino_id = current_casino_id
    @remain_limit = @player.remain_trans_amount(:deposit, @casino_id)
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type)
    wallet_requester.deposit(member_id, amount, ref_trans_id, trans_date, source_type, current_user.uid, current_user.name)
  end
  
  def extract_params
    super
    @is_player_deposit = params[:player_transaction][:non_player_deposit] == "0"
    @deposit_reason = params[:player_transaction][:deposit_reason]
    @data[:is_player_deposit] = @is_player_deposit
    @data[:deposit_reason] = @deposit_reason
  end
end
