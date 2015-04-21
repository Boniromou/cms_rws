module Hood
  class WithdrawTransaction < WalletTransaction
    
    def apply_to_player(player)
      raise AmountNotEnough.new(:balance=>AmtUtil.cent2dollar(player[:balance])) if player[:balance] < self[:amt]
      player[:balance] -= self[:amt]
    end

  end
end

