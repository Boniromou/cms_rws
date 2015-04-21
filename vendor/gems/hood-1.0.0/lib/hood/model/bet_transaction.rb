module Hood
  class BetTransaction < RoundTransaction
    include Loggable

    class << self
      def process(player,ib)
        ct = CancelBetTransaction.find_cancel_bet(ib[:ref_trans_id])
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
      if self[:player_id] == player[:id] && self[:bet_amt] == ib[:bet_amt] && self[:aasm_state] == 'completed'
        raise AlreadyProcessed.new(to_res)
      else
        raise DuplicateTrans
      end
    end

    def accept(player,ib)
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

    def init(player,ib)
      base_init(player,ib)
      self[:ref_trans_id] = ib[:ref_trans_id]
      self[:bet_amt] = ib[:bet_amt]
    end

    def apply_to_player(player)
      super(player)
      raise AmountNotEnough.new(:balance=>AmtUtil.cent2dollar(player[:balance])) if player[:balance] < self[:bet_amt]
      player[:balance] -= self[:bet_amt]
    end

  end

end
