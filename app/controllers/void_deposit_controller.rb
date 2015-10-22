class VoidDepositController < FundController
  def operation_sym
    :void_deposit?
  end

  def operation_str
    "void_deposit"
  end

  def action_str
    "void_deposit"
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, shift_id, station_id, user_id)
    wallet_requester.void_deposit(member_id, amount, ref_trans_id, trans_date, shift_id, station_id, user_id)
  end
end
