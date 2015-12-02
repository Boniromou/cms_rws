class FundOutController < FundController

  def operation_sym
    :withdraw?
  end

  def action_str
    "withdraw"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date)
  end
end
