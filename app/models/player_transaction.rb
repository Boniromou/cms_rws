class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :station_id, :status, :transaction_type_id, :user_id, :created_at
  belongs_to :player
  belongs_to :shift
  belongs_to :user
  belongs_to :transaction_type

  include FundHelper
  include ActionView::Helpers

  DEPOSIT = 'deposit'
  WITHDRAW = 'withdraw'
  VOID_DEPOSIT = 'void_deposit'
  VOID_WITHDRAW = 'void_withdraw'

  def deposit_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == DEPOSIT
    result
  end

  def withdraw_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == WITHDRAW
    result
  end

  def completed!
    self.status = 'completed'
    self.save!
  end

  def rejected!
    self.status = 'rejected'
    self.save!
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

    def init_player_transaction(member_id, amount, trans_type, shift_id, user_id, station_id)
      player_id = Player.find_by_member_id(member_id)[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:transaction_type_id] = TransactionType.find_by_name(trans_type).id;
      transaction[:shift_id] = shift_id
      transaction[:station_id] = station_id
      transaction[:status] = "pending"
      transaction[:user_id] = user_id
      transaction[:trans_date] = Time.now
      transaction.save
      transaction.reload
      transaction[:ref_trans_id] = make_trans_id(transaction.id)
      transaction.save
      transaction
    end

    def save_deposit_transaction(member_id, amount, shift_id, user_id, station_id)
      init_player_transaction(member_id, amount, DEPOSIT, shift_id, user_id, station_id)
    end

    def save_withdraw_transaction(member_id, amount, shift_id, user_id, station_id)
      init_player_transaction(member_id, amount, WITHDRAW, shift_id, user_id, station_id)
    end

    def save_void_deposit_transaction(member_id, amount, shift_id, user_id, station_id)
      init_player_transaction(member_id, amount, VOID_DEPOSIT, shift_id, user_id, station_id)
    end

    def save_void_withdraw_transaction(member_id, amount, shift_id, user_id, station_id)
      init_player_transaction(member_id, amount, VOID_WITHDRAW, shift_id, user_id, station_id)
    end

    def get_player_by_card_member_id(type, id)
      if type == "member_id"
        Player.find_by_member_id(id)
      else
        Player.find_by_card_id(id)
      end
    end

    def search_query_by_player(id_type, id_number, start_shift_id, end_shift_id)      
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
      by_transaction_id(transaction_id)
    end

    def search_query(*args)
      search_type = args[5].to_i
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
