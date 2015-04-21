module Hood
  class WalletTransaction < Sequel::Model
    include Loggable

    MODEL_MAP = {"deposit"=>"Hood::DepositTransaction","withdraw"=>"Hood::WithdrawTransaction"}
    plugin :single_table_inheritance, :trans_type, :model_map=> MODEL_MAP

    class << self
      def new_transaction(trans_type)
        Hood.const_get(MODEL_MAP[trans_type.to_s].split('::').last).new
      end

      def process(player,ib)
        t = WalletTransaction[:ref_trans_id=>ib[:ref_trans_id],:property_id=>ib[:property_id]]
        if t
          t.handle_duplicate_req(player,ib)
        else
          t = new_transaction(ib[:_event_name])
          t.accept(player,ib)
        end
      end

      def query_transactions(property_id,from_time,to_time)
        time_zone = Property.get_time_zone(property_id)
        from_t,to_t = TimeUtil.check_time_range(from_time,to_time,time_zone)
        transactions = WalletTransaction.db[:wallet_transactions___t].join(:players___p,:id=>:player_id).where(:t__property_id=>property_id,:t__aasm_state=>'completed').where{(t__created_at>=from_t) & (t__created_at<to_t)}.select(:ref_trans_id,:login_name,:trans_date,:amt,:before_balance,:after_balance,:trans_type,:aasm_state___status).all
        transactions.each do |t|
          t[:amt] = AmtUtil.cent2dollar(t[:amt])
          t[:before_balance] = AmtUtil.cent2dollar(t[:before_balance])
          t[:after_balance] = AmtUtil.cent2dollar(t[:after_balance])
          t[:trans_date] = TimeUtil.to_local_str(t[:trans_date],time_zone)
        end
        {:transactions => transactions}
      end
    end

    def handle_duplicate_req(player,ib)
      if self[:trans_type] == ib[:_event_name].to_s && self[:player_id] == player[:id] && self[:amt] == ib[:amt] && self[:aasm_state] == 'completed'
        raise AlreadyProcessed
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
      {:amt=>AmtUtil.cent2dollar(self[:amt]),:before_balance=>AmtUtil.cent2dollar(self[:before_balance]),
        :after_balance=>AmtUtil.cent2dollar(self[:after_balance])}
    end

    def init(player,ib)
      self[:player_id] = player[:id]
      self[:property_id] = player[:property_id]
      self[:ref_trans_id] = ib[:ref_trans_id]
      self[:amt] = ib[:amt]
      self[:trans_date] = Time.parse(ib[:trans_date] + Property.get_time_zone(self[:property_id]))
    end

  end
end
