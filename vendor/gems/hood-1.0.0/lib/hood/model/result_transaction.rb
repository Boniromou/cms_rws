module Hood
  class ResultTransaction < RoundTransaction
    include Loggable

    class << self
      def process(player,ib)
        t = ResultTransaction[:ref_trans_id=>ib[:ref_trans_id]]
        if t
          t.handle_duplicate_req(player,ib)
        else
          t = ResultTransaction.new
          t.accept(player,ib)
        end
      end
    end

    def handle_duplicate_req(player,ib)
      if self[:player_id] == player[:id] && self[:payout_amt] == ib[:payout_amt] && self[:aasm_state] == 'completed'
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
      self[:win_amt] = ib[:win_amt]
      self[:payout_amt] = ib[:payout_amt]
      self[:jc_jp_con_amt] = ib[:jc_jp_con_amt]
      self[:jc_jp_win_amt] = ib[:jc_jp_win_amt]
      self[:pc_jp_con_amt] = ib[:pc_jp_con_amt]
      self[:pc_jp_win_amt] = ib[:pc_jp_win_amt]
      self[:jp_win_id] = ib[:jp_win_id]
      self[:jp_win_lev] = ib[:jp_win_lev]
      self[:jp_direct_pay] = (ib[:jp_direct_pay] == 0 ? false : true)
    end

    def apply_to_player(player)
      super(player)
      player[:balance] += self[:payout_amt]
      player[:balance] += AmtUtil.dollar2cent(self[:pc_jp_win_amt]) if self[:jp_direct_pay]
    end

  end

end
