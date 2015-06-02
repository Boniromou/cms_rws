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

  def call_iwms(member_id, amount, ref_trans_id, trans_date)
    iwms_requester.deposit(member_id, amount, ref_trans_id, trans_date)
  end
end
