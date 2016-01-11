module Hood
  class CreditDepositTransaction < CashierTransaction
    
    def apply_to_player(player,ib)
      raise CreditNotExpired.new(player.balance_info) if player[:credit_balance] > 0
      player[:credit_balance] += self[:credit_amt]
      player[:credit_expired_at] = Time.parse(ib[:credit_expired_at] + Property.get_time_zone(player[:property_id])).utc
    end

  end
end

