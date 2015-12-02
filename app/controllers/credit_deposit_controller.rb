class CreditDepositController < FundController
  def operation_sym
    :credit_deposit?
  end

  def action_str
    "credit_deposit"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.credit_deposit(member_id, amount, ref_trans_id, trans_date)
  end
end
