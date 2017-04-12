module TransactionQueries
  def self.included(base)
    base.instance_eval do
      scope :since, -> start_time { where("created_at >= ?", start_time) if start_time.present? }
      scope :until, -> end_time { where("created_at <= ?", end_time) if end_time.present? }
      scope :by_player_id, -> player_id { where("player_id = ?", player_id) if player_id.present? }
      scope :by_transaction_id, -> transaction_id { where("id = ?", transaction_id) if transaction_id.present? }
      scope :by_shift_id, -> shift_id { where( "shift_id = ? ", shift_id) if shift_id.present? }
      scope :by_user_id, -> user_id { where( "user_id = ?", user_id) if user_id.present? }
      scope :by_transaction_type_id, -> trans_types { where(:transaction_type_id => trans_types) if trans_types.present?}
      scope :from_shift_id, -> shift_id { where( "shift_id >= ? ", shift_id) if shift_id.present? }
      scope :to_shift_id, -> shift_id { where( "shift_id <= ? ", shift_id) if shift_id.present? }
      scope :in_shift_id, -> shift_id { where( "shift_id in (?) ", shift_id) if shift_id.present? }
      scope :by_slip_number, -> slip_number { where("slip_number = ?", slip_number) if slip_number.present? }
      scope :by_status, -> status { where( :status => status) if status.present? }
      scope :by_casino_id, -> casino_id { where("casino_id = ?", casino_id) if casino_id.present? }
    end

    base.extend ClassMethods
  end

  module ClassMethods
    TRANSACTION_TYPE_ID_LIST = {:deposit => 1, :withdraw => 2, :void_deposit => 3, :void_withdraw => 4, :credit_deposit => 5, :credit_expire => 6}

    def only_deposit_withdraw
      by_transaction_type_id([TRANSACTION_TYPE_ID_LIST[:deposit], TRANSACTION_TYPE_ID_LIST[:withdraw]]).by_status(['completed', 'pending'])
    end

    def only_credit_deposit_expire
      by_transaction_type_id([TRANSACTION_TYPE_ID_LIST[:credit_deposit], TRANSACTION_TYPE_ID_LIST[:credit_expire]]).by_status(['completed', 'pending'])
    end

    def search_query_by_player(id_type, id_number, start_shift_id, end_shift_id, operation)      
      if id_number.empty?
        player_id = nil
      else
        player_id = 0
        player = Player.find_by_id_type_and_id_number(id_type.to_sym, id_number)
        player_id = player.id unless player.nil?
      end
      if operation == 'cash'
        by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_deposit_withdraw
      else
        by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_credit_deposit_expire
      end
    end

    def daily_transaction_amount_by_player(player, accounting_date, trans_type, casino_id)
      start_shift_id = accounting_date.shifts.where(:casino_id => casino_id).first.id
      end_shift_id = accounting_date.shifts.where(:casino_id => casino_id).last.id
      select('sum(amount) as amount').by_player_id(player.id).by_casino_id(casino_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).by_transaction_type_id(TRANSACTION_TYPE_ID_LIST[trans_type]).first.amount || 0
    end
  end
  
end
