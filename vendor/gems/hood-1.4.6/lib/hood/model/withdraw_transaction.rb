module Hood
  class WithdrawTransaction < CashierTransaction
    
    def apply_to_player(player,ib)
      raise AmountNotEnough.new(player.balance_info) if player[:balance] < self[:amt]
      player[:balance] -= self[:amt]
    end

  end
end

