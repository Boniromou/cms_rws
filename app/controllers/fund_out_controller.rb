class FundOutController < FundController
  rescue_from BalanceNotEnough, :with => :handle_balance_not_enough
  def operation_sym
    :withdraw?
  end

  def operation_str
    "fund_out"
  end

  def action_str
    "withdrawal"
  end

  def get_server_amount(amount)
    server_amount = super(amount)
    balance = @player.balance
    validate_balance_enough( server_amount, balance )
    server_amount
  end
  
  def handle_balance_not_enough(e)
    handle_fund_error({ key: "invalid_amt.no_enough_to_withdrawal", replace: { balance: @player.balance_str} })
  end
end
