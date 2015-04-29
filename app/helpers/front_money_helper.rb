module FrontMoneyHelper
  def report_balance(balance)
    if balance >=0
      return balance
    else
      return "(#{-balance})"
    end
  end
end
