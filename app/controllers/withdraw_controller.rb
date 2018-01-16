class WithdrawController < FundController
  def new
    super
    @casino_id = current_casino_id
    @remain_limit = @player.remain_trans_amount(:withdraw, @casino_id)
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type, machine_token)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date, source_type, current_user.id, current_user.name, machine_token)
  end

  def check_transaction_acceptable
    super
    validate_pin
  end
end
