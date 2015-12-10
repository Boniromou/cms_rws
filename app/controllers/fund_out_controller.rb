class FundOutController < FundController
  def action_str
    "withdraw"
  end

  def need_validate?
    true
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date)
  end
end
