class DepositController < FundController
  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.deposit(member_id, amount, ref_trans_id, trans_date)
  end
end