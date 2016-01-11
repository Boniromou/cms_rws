module Hood
  module WalletTransaction #< Sequel::Model

    def accept(player,ib)
      Player.db.transaction do
        init(player,ib)
        self[:before_balance] = player[:balance]
        self[:credit_before_balance] = player[:credit_balance]
        apply_to_player(player,ib)
        self[:after_balance] = player[:balance]
        self[:credit_after_balance] = player[:credit_balance]
        self[:aasm_state] = 'completed'
        player[:seq] = 0 if player[:seq].nil?
        player[:seq] += 1
        self[:seq] = player[:seq]
        player.save_changes
        self.save
      end
      to_res(player)
    end

    def to_res(player)
      time_zone = Property.get_time_zone(player[:property_id])
      trans_date = TimeUtil.to_local_str(self[:created_at],time_zone)
      info = {:amt=>AmtUtil.cent2dollar(self[:amt]),:before_balance=>AmtUtil.cent2dollar(self[:before_balance]),
                :after_balance=>AmtUtil.cent2dollar(self[:after_balance]),:trans_date=>trans_date}
      if player.credit_enable?
        info[:credit_amt] = AmtUtil.cent2dollar(self[:credit_amt])
        info[:credit_before_balance] = AmtUtil.cent2dollar(self[:credit_before_balance])
        info[:credit_after_balance] = AmtUtil.cent2dollar(self[:credit_after_balance])
        if player[:credit_expired_at]
          info[:credit_expired_at] = TimeUtil.to_local_str(player[:credit_expired_at],time_zone)
        end
      end
      info
    end

  end
end
