class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :station_id, :status, :transaction_type_id, :user_id, :created_at
  include FundHelper
  include ActionView::Helpers

  DEPOSIT = 1
  WITHDRAWAL = 2

  TRANSACTION_TYPE_STR = {
    DEPOSIT: "Deposit",
    WITHDRAWAL: "Withdrawal"
  }

  def deposit_amt_str
    result = ""
    result = to_display_amount_str(amount) if transaction_type_id == DEPOSIT
    result
  end

  def withdrawal_amt_str
    result = ""
    result = to_display_amount_str(amount) if transaction_type_id == WITHDRAWAL
    result
  end

  def action_type_str
    TRANSACTION_TYPE_STR[transaction_type_id]
  end    

  scope :since, -> start_time { where("created_at >= ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("created_at <= ?", end_time) if end_time.present? }
  scope :by_player_id, -> player_id { where("player_id = ?", player_id) if player_id.present? }
  scope :by_transaction_id, -> transaction_id { where("id = ?", transaction_id) if transaction_id.present? }
  scope :by_shift_id, -> shift_id { where( "shift_id = ? ", shift_id) if shift_id.present? }
  scope :by_station_id, -> station_id { where( "station_id = ?", station_id) if station_id.present? }
  scope :by_user_id, -> user_id { where( "user_id = ?", user_id) if user_id.present? }
  scope :from_shift_id, -> shift_id { where( "shift_id >= ? ", shift_id) if shift_id.present? }
  scope :to_shift_id, -> shift_id { where( "shift_id <= ? ", shift_id) if shift_id.present? }

  class << self
  include FundHelper
    def instance
      @player_transaction = PlayerTransaction.new unless @player_transaction
      @player_transaction
    end

    def save_fund_in_transaction(member_id, amount, shift_id, user_id, station_id)
      player_id = Player.find_by_member_id(member_id)[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:shift_id] = shift_id
      transaction[:station_id] = station_id
      transaction[:status] = "completed"
      transaction[:transaction_type_id] = TransactionType.find_by_name("Deposit").id;
      transaction[:user_id] = user_id
      transaction[:trans_date] = Time.now
      transaction.save
      transaction.reload
      transaction[:ref_trans_id] = make_trans_id(transaction.id)
      transaction.save
      transaction
    end

    def save_fund_out_transaction(member_id, amount, shift_id, user_id, station_id)
      player_id = Player.find_by_member_id(member_id)[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:shift_id] = shift_id
      transaction[:station_id] = station_id
      transaction[:status] = "completed"
      transaction[:transaction_type_id] = TransactionType.find_by_name("Withdrawal").id;
      transaction[:user_id] = user_id
      transaction[:trans_date] = Time.now
      transaction.save
      transaction.reload
      transaction[:ref_trans_id] = make_trans_id(transaction.id)
      transaction.save
      transaction
    end

    def get_player_by_card_member_id(type, id)
      if type == "member_id"
        Player.find_by_member_id(id)
      else
        Player.find_by_card_id(id)
      end
    end

    def search_query_by_player(id_type, id_number, start_shift_id, end_shift_id)
      # raise SearchPlayerTransaction::NoIdNumberError, "no_id_number" if id_number.blank?
      # raise SearchPlayerTransaction::OverRangeError, "limit_remark" if end_time - start_time > 2592200
      
      if id_number.empty?
        player_id = nil
      else
        player_id = 0
        player = get_player_by_card_member_id(id_type, id_number)
        player_id = player.id unless player.nil?
      end

      by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id)
    end

    def search_query_by_transaction(transaction_id)
      p transaction_id
      by_transaction_id(transaction_id)
    end

    def search_query(*args)
      search_type = args[5].to_i
      p search_type
      if search_type == 0
        id_type = args[0]
        id_number = args[1]
        start_shift_id = args[2]
        end_shift_id = args[3]

        search_query_by_player(id_type, id_number, start_shift_id, end_shift_id)
      else
        transaction_id = args[4].to_i

        search_query_by_transaction(transaction_id)
      end
    end

    def search_transactions_group_by_station(start_shift_id, user_id, end_shift_id = nil)
      player_transaction_stations = PlayerTransaction.select(:station_id).group(:station_id)
      p player_transaction_stations
      result = []
      player_transactions = PlayerTransaction.by_shift_id(start_shift_id)
      player_transactions = PlayerTransaction.from_shift_id(start_shift_id).to_shift_id(end_shift_id) if end_shift_id
      player_transaction_stations.each do |station|
        station_id = station.station_id
        player_transactions_by_station = player_transactions.by_station_id(station_id).by_user_id(user_id).order(:created_at)
        result << player_transactions_by_station if player_transactions_by_station.length > 0
      end
      result
    end
  end
end
