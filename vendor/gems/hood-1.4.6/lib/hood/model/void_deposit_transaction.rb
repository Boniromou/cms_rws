module Hood
  class VoidDepositTransaction < VoidTransaction
    
    def apply_to_player(player,ib)
      raise AmountNotEnough.new(:balance=>AmtUtil.cent2dollar(player[:balance])) if player[:balance] < self[:amt]
      player[:balance] -= self[:amt]
    end

  end
end

