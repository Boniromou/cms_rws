module PlayersHelper
  def can_credit_deposit(credit_balance)
    credit_balance.class == Float && credit_balance == 0
  end

  def can_credit_expire(credit_balance)
    credit_balance.class == Float && credit_balance > 0 
  end
end
