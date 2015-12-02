class CreditDepositController < FundController
  def operation_sym
    :credit_deposit?
  end

  def action_str
    "credit_deposit"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
  	credit_expired_at = Time.now.utc + CREDIT_LIFE_TIME
    wallet_requester.credit_deposit(member_id, amount, ref_trans_id, trans_date, credit_expired_at)
  end
end
