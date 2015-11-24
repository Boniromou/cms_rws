class CreditExpireController < FundController

  def operation_sym
    :credit_expire?
  end

  def operation_str
    "credit_expire"
  end

  def action_str
    "credit_expire"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.credit_expire(member_id, amount, ref_trans_id, trans_date)
  end
end
