module Hood
  class CreditExpireTransaction < CashierTransaction
    
    def apply_to_player(player,ib)
      raise AmountNotMatch.new(player.balance_info) if self[:credit_amt] != player[:credit_balance]
      player[:credit_balance] = 0
      player[:credit_expired_at] = Time.now if player[:credit_expired_at] > Time.now
    end

  end
end

