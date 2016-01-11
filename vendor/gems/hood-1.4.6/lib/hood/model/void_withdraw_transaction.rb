module Hood
  class VoidWithdrawTransaction < VoidTransaction

    def apply_to_player(player,ib)
      player[:balance] += self[:amt]
    end

  end
end

