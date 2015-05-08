module FrontMoneyHelper
  include FundHelper
  def report_balance(balance)
    if balance >=0
      return to_display_amount_str(balance)
    else
      return "(#{to_display_amount_str(-balance)})"
    end
  end
  
  class NoResultException < Exception
  end
end
