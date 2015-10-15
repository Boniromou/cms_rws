class FundOutController < FundController
  rescue_from Remote::AmountNotEnough, :with => :handle_balance_not_enough

  def operation_sym
    :withdraw?
  end

  def operation_str
    "fund_out"
  end

  def action_str
    "withdrawal"
  end

  def handle_balance_not_enough(e)
    handle_fund_error({ key: "invalid_amt.no_enough_to_withdrawal", replace: { balance: to_formatted_display_amount_str(e.message.to_f)} })
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, shift_id, station_id, user_id)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date, shift_id, station_id, user_id)
  end
end
