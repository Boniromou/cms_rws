class FundOutController < FundController

  def operation_sym
    :withdraw?
  end

  def operation_str
    "fund_out"
  end

  def action_str
    "withdraw"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, shift_id, machine_token, user_id)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date, shift_id, machine_token, user_id)
  end
end
