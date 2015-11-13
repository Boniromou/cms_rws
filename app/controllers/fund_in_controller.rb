class FundInController < FundController
  def operation_sym
    :deposit?
  end

  def operation_str
    "fund_in"
  end

  def action_str
    "deposit"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, shift_id, machine_token, user_id)
    wallet_requester.deposit(member_id, amount, ref_trans_id, trans_date, shift_id, machine_token, user_id)
  end
end
