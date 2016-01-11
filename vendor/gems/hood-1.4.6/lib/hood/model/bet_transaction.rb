module Hood
  class BetTransaction < RoundTransaction
    include Loggable

    class << self
      def process(player,ib)
        ValidateTokenService.new.validate_token(ib[:property_id], ib[:login_name], ib[:session_token])
        ct = CancelBetTransaction[:ref_trans_id=>ib[:ref_trans_id]]
        if ct
          raise AlreadyCancelled
        end
        t = BetTransaction[:ref_trans_id=>ib[:ref_trans_id]]
        if t
          t.handle_duplicate_req(player,ib)
        else
          t = BetTransaction.new
          t.accept(player,ib)
        end
      end
    end

    def handle_duplicate_req(player,ib)
      if self[:player_id]==player[:id] && (self[:bet_amt]+self[:credit_bet_amt]==ib[:bet_amt]) && self[:aasm_state]=='completed'
        raise AlreadyProcessed.new(to_res(player))
      else
        raise DuplicateTrans
      end
    end

    def init(player,ib)
      base_init(player,ib)
      self[:ref_trans_id] = ib[:ref_trans_id]
      self[:total_bet_amt] = ib[:bet_amt]
      self[:bet_amt] = ib[:bet_amt]
      self[:credit_bet_amt] = 0
    end

    def apply_to_player(player,ib)
      super(player,ib)
      raise AmountNotEnough.new(player.balance_info) if player[:balance] < self[:bet_amt]
      if player.credit_enable?
        if player[:credit_balance] >= self[:bet_amt]
          self[:credit_bet_amt] = self[:bet_amt]
          self[:bet_amt] = 0
        else
          self[:credit_bet_amt] = player[:credit_balance]
          self[:bet_amt] -= self[:credit_bet_amt]
        end
      end
      player[:balance] -= self[:bet_amt]
      player[:credit_balance] -= self[:credit_bet_amt]
    end

  end

end
