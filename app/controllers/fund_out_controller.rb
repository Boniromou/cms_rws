class FundOutController < FundController
  def operation_sym
    :withdraw?
  end

  def operation_str
    "fund_out"
  end

  def action_str
    "withdrawal"
  end
end
