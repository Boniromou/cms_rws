class WithdrawController < FundController

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date)
  end

  def check_transaction_acceptable
    super
    validate_pin
  end
end
