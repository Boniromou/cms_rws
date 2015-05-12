module FundHelper
  def validate_amount_str( amount )
    raise AmountInvalidError.new "Input amount not valid" unless amount.is_a?(String) && amount =~ /^\d{1,7}(\.\d{1,2})?$/ && to_server_amount( amount ) > 0
  end

  def to_server_amount( amount )
    (amount.to_f.round(2) * 100).to_i
  end

  def validate_balance_enough( amount , balance)
    raise  BalanceNotEnough.new "Input amount not valid" unless balance >= amount
  end

  def to_display_amount_str( amount )
    number_to_currency(amount.to_f / 100).sub("$","")
  end

  class AmountInvalidError < Exception
  end

  class BalanceNotEnough < Exception
  end
end
