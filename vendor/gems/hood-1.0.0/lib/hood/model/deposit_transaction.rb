module Hood
  class DepositTransaction < WalletTransaction
    
    def apply_to_player(player)
      player[:balance] += self[:amt]
    end

  end
end

