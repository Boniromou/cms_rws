module FundHelper
  def validate_amount_str( amount )
    raise "Input amount not valid" unless amount.is_a?(String) && amount =~ /^\d+(\.\d{1,2})?$/ && to_server_amount( amount ) > 0
  end

  def to_server_amount( amount )
    (amount.to_f.round(2) * 100).to_i
  end

  def validate_balance_enough( amount , balance)
    raise "Input amount not valid" unless balance > amount
  end

  def to_display_amount_str( amount )
    "%0.2f" % (amount.to_f / 100)
  end
end
