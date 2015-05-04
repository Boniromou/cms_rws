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
end
