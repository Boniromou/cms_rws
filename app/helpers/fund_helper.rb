module FundHelper
  include ActionView::Helpers::NumberHelper
  def validate_amount_str( amount )
    raise FundInOut::AmountInvalidError.new "Input amount not valid" unless amount.is_a?(String) && amount =~ /^\d{1,7}(\.\d{1,2})?$/ && to_server_amount( amount ) > 0
  end

  def is_amount_str_valid?( amount)
    amount.is_a?(String) && amount =~ /^\d+(\.\d{1,2})?$/ && to_server_amount( amount ) > 0
  end

  def to_server_amount( amount )
    (amount.to_f.round(2) * 100).to_i
  end

  def cents_to_dollar(cent_amount)
    (cent_amount.to_f/100.0).to_f
  end

  def validate_balance_enough( amount , balance)
    raise  BalanceNotEnough.new "Input amount not valid" unless balance >= amount
  end

  def to_display_amount_str( amount )
    return I18n.t("balance_enquiry.#{amount}") if amount.class == String
    number_to_currency(amount.to_f / 100).sub("$","")
  end

  def to_formatted_display_amount_str( amount )
    return I18n.t("balance_enquiry.#{amount}") if amount.class == String
    number_to_currency(amount).sub("$","")
  end

  def to_display_remain_str(remain_amt)
    if remain_amt >= 0
      to_display_amount_str(remain_amt)
    else
      I18n.t('deposit_withdrawal.exceed_remain_limit')
    end
  end

  def make_trans_id(id)
    str = ("0x%08x" % (id))
    str = str[2, str.length - 2] if str.start_with?('0x')
    "C#{str.upcase}"
  end
end
