class CreditExpireController < FundController
  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.credit_expire(member_id, amount, ref_trans_id, trans_date)
  end
end
