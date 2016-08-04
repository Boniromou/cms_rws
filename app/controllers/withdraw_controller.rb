class WithdrawController < FundController

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date, source_type)
  end

  def check_transaction_acceptable
    super
    validate_pin
  end
end
