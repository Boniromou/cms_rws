module Hood
  class RoundTransaction < Sequel::Model
    include Loggable

    MODEL_MAP = {"bet"=>"Hood::BetTransaction","cancel_bet"=>"Hood::CancelBetTransaction","result"=>"Hood::ResultTransaction"}
    plugin :single_table_inheritance, :trans_type, :model_map=> MODEL_MAP

    class << self
      def query_transactions(property_id,from_time,to_time)
        time_zone = Property.get_time_zone(property_id)
        from_t,to_t = TimeUtil.check_time_range(from_time,to_time,time_zone)
        transactions = RoundTransaction.db[:round_transactions___t].join(:players___p,:id=>:player_id).where(:t__property_id=>property_id,:t__aasm_state=>'completed').where{(t__created_at>=from_t) & (t__created_at<to_t)}.select(:ref_trans_id,:login_name,:trans_date,:before_balance,:after_balance,:trans_type,:round_id,:bet_amt,:payout_amt,:win_amt,:jc_jp_con_amt,:jc_jp_win_amt,:pc_jp_con_amt,:pc_jp_win_amt,:jp_win_id,:jp_win_lev,:jp_direct_pay,:aasm_state___status,:external_game_id___game_id).all
        transactions.each do |t|
          t.delete_if {|k,v| v==nil}
          if t[:trans_type] == 'result'
            [:payout_amt,:win_amt].each { |k| t[k] = AmtUtil.cent2dollar(t[k]) }
            [:pc_jp_con_amt,:pc_jp_win_amt,:jc_jp_con_amt,:jc_jp_win_amt].each do |k|
              t[k] = t[k].to_s("F") if t[k]
            end
          else
            t[:bet_amt] = AmtUtil.cent2dollar(t[:bet_amt])
          end
          [:before_balance,:after_balance].each { |k| t[k] = AmtUtil.cent2dollar(t[k]) }
          t[:trans_date] = TimeUtil.to_local_str(t[:trans_date],time_zone)
        end
        {:transactions => transactions}
      end
    end

    def base_init(player,ib)
      self[:player_id] = player[:id]
      self[:property_id] = player[:property_id]
      self[:trans_date] = Time.parse(ib[:trans_date] + "+08:00")
      self[:round_id] = ib[:round_id]
      self[:internal_game_id] = ib[:internal_game_id]
      self[:external_game_id] = ib[:external_game_id]
    end

    def apply_to_player(player)
      player[:played_at] = Time.now.utc
    end

    def to_res
      {:before_balance=>AmtUtil.cent2dollar(self[:before_balance]),:balance=>AmtUtil.cent2dollar(self[:after_balance])}
    end
  end
end
