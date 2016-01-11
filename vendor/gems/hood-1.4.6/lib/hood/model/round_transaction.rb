module Hood
  class RoundTransaction < Sequel::Model
    include WalletTransaction
    include Loggable

    MODEL_MAP = {"bet"=>"Hood::BetTransaction","cancel_bet"=>"Hood::CancelBetTransaction","result"=>"Hood::ResultTransaction"}
    plugin :single_table_inheritance, :trans_type, :model_map=> MODEL_MAP

    class << self
      def query_result_transactions(property_id,from_time,to_time)
        time_zone = Property.get_time_zone(property_id)
        from_t,to_t = TimeUtil.check_time_range(from_time,to_time,time_zone)
        transactions = RoundTransaction.db[:round_transactions___t].join(:players___p,:id=>:player_id).where(:trans_type=>'result').where(:t__property_id=>property_id,:t__aasm_state=>'completed').where{(t__created_at>=from_t) & (t__created_at<to_t)}.select(:ref_trans_id,:login_name,:t__created_at___trans_date,:round_id,:total_bet_amt___bet_amt,:payout_amt,:win_amt,:jc_jp_con_amt,:jc_jp_win_amt,:pc_jp_con_amt,:pc_jp_win_amt,:jp_win_id,:jp_win_lev,:jp_direct_pay,:aasm_state___status,:external_game_id___game_id).all
        transactions.each do |t|
          t.delete_if {|k,v| v==nil}
          [:bet_amt,:payout_amt,:win_amt].each { |k| t[k] = AmtUtil.cent2dollar(t[k]) }
          [:pc_jp_con_amt,:pc_jp_win_amt,:jc_jp_con_amt,:jc_jp_win_amt].each do |k|
            t[k] = t[k].to_s("F") if t[k]
          end
          t[:trans_date] = TimeUtil.to_local_str(t[:trans_date],time_zone)
        end
        {:transactions => transactions}
      end
    end

    #

    def base_init(player,ib)
      self[:player_id] = player[:id]
      self[:property_id] = player[:property_id]
      self[:trans_date] = Time.parse(ib[:trans_date] + "+08:00")
      self[:round_id] = ib[:round_id]
      self[:internal_game_id] = ib[:internal_game_id]
      self[:external_game_id] = ib[:external_game_id]
      self[:machine_token] = ib[:machine_token]
    end

    def apply_to_player(player,ib)
      player[:played_at] = Time.now.utc
    end

    def to_res(player)
      info = super(player)
      info[:balance] = info.delete(:after_balance)
      info[:credit_balance] = info.delete(:credit_after_balance)
      info
    end

  end
end
