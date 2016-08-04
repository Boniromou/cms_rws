class VoidDepositController < VoidController
  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type)
    wallet_requester.void_deposit(member_id, amount, ref_trans_id, trans_date, source_type)
  end
end
