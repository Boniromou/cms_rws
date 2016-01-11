module Hood
  class CancelBetTransaction < RoundTransaction
    include Loggable

    class << self
      def process(player,ib)
        t = CancelBetTransaction[:ref_trans_id=>ib[:ref_trans_id]]
        if t
          t.handle_duplicate_req(player,ib)
        else
          bt = BetTransaction[:ref_trans_id=>ib[:ref_trans_id]]
          if bt
            raise CancelBetNotMatch unless (bt[:bet_amt]+bt[:credit_bet_amt]==ib[:bet_amt] && bt[:player_id]==player[:id])
            ib[:total_bet_amt] = bt[:total_bet_amt]
            ib[:bet_amt] = bt[:bet_amt]
            ib[:credit_bet_amt] = bt[:credit_bet_amt]
            t = CancelBetTransaction.new
            t.accept(player,ib)
          else
            t = CancelBetTransaction.new
            t.reject(player,ib)
          end
        end
      end
    end

    def handle_duplicate_req(player,ib)
      if self[:player_id] == player[:id] && self[:bet_amt]+self[:credit_bet_amt] == ib[:bet_amt]
        #if self[:aasm_state] == 'completed'
        raise AlreadyProcessed
      else
        raise DuplicateTrans
      end
    end

    def reject(player,ib)
      ib[:credit_bet_amt] = 0
      CashierTransaction.db.transaction do
        init(player,ib)
        self[:before_balance] = player[:balance]
        self[:after_balance] = player[:balance]
        self[:credit_before_balance] = player[:credit_balance]
        self[:credit_after_balance] = player[:credit_balance]
        self[:aasm_state] = 'rejected'
        self.save
      end
      raise CancelBetNotExist
    end

    def init(player,ib)
      base_init(player,ib)
      self[:ref_trans_id] = ib[:ref_trans_id]
      self[:total_bet_amt] = ib[:total_bet_amt]
      self[:bet_amt] = ib[:bet_amt]
      self[:credit_bet_amt] = ib[:credit_bet_amt]
    end

    def apply_to_player(player,ib)
      super(player,ib)
      player[:balance] += self[:bet_amt]
      player[:credit_balance] += self[:credit_bet_amt]
    end

  end
end
