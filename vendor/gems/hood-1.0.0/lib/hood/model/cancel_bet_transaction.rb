module Hood
  class CancelBetTransaction < RoundTransaction
    include Loggable

    class << self
      def process(player,ib)
        t = find_cancel_bet(ib[:ref_trans_id])
        if t
          t.handle_duplicate_req(player,ib)
        else
          bt = BetTransaction[:ref_trans_id=>ib[:ref_trans_id]]
          if bt
            raise CancelBetNotMatch unless (bt[:bet_amt]==ib[:bet_amt] && bt[:player_id]==player[:id])
            t = CancelBetTransaction.new
            t.process(player,ib)
          else
            t = CancelBetTransaction.new
            t.reject(player,ib)
          end
        end
      end

      def find_cancel_bet(ref_trans_id)
        CancelBetTransaction[:ref_trans_id=>"-#{ref_trans_id}"]
      end
    end

    def handle_duplicate_req(player,ib)
      if self[:player_id] == player[:id] && self[:bet_amt] == ib[:bet_amt]
        #if self[:aasm_state] == 'completed'
        raise AlreadyProcessed
      else
        raise DuplicateTrans
      end
    end

    def process(player,ib)
      WalletTransaction.db.transaction do
        init(player,ib)
        self[:before_balance] = player[:balance]
        apply_to_player(player)
        self[:after_balance] = player[:balance]
        self[:aasm_state] = 'completed'
        self.save
        player.save_changes
      end
      to_res
    end

    def reject(player,ib)
      WalletTransaction.db.transaction do
        init(player,ib)
        self[:before_balance] = player[:balance]
        self[:after_balance] = player[:balance]
        self[:aasm_state] = 'rejected'
        self.save
      end
      raise CancelBetNotExist
    end

    def init(player,ib)
      base_init(player,ib)
      self[:ref_trans_id] = "-" + ib[:ref_trans_id]
      self[:bet_amt] = ib[:bet_amt]
    end

    def apply_to_player(player)
      super(player)
      player[:balance] += self[:bet_amt]
    end

  end
end
