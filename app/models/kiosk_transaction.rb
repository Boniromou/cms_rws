class KioskTransaction < ActiveRecord::Base
  attr_accessible :player_id, :shift_id, :transaction_type_id, :ref_trans_id, :amount, :status, :casino_id, :source_type, :created_at
  belongs_to :player
  belongs_to :shift
  belongs_to :transaction_type
  belongs_to :casino

  include FundHelper
  include ActionView::Helpers

  DEPOSIT = 'deposit'
  WITHDRAW = 'withdraw'

  TRANSACTION_TYPE_ID_LIST = {:deposit => 1, :withdraw => 2, :void_deposit => 3, :void_withdraw => 4, :credit_deposit => 5, :credit_expire => 6}

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
    KioskTransaction.transaction do
      self.status = 'completed'
      self.save!
    end
  end

  def rejected!
    self.status = 'rejected'
    self.save!
  end

  def display_status
    self.status
  end

  def voided?
    display_status == 'voided'
  end

  def can_void?
    false
  end
  
  scope :since, -> start_time { where("created_at >= ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("created_at <= ?", end_time) if end_time.present? }
  scope :by_player_id, -> player_id { where("player_id = ?", player_id) if player_id.present? }
  scope :by_transaction_id, -> transaction_id { where("id = ?", transaction_id) if transaction_id.present? }
  scope :by_shift_id, -> shift_id { where( "shift_id = ? ", shift_id) if shift_id.present? }
  scope :by_transaction_type_id, -> trans_types { where(:transaction_type_id => trans_types) if trans_types.present?}
  scope :from_shift_id, -> shift_id { where( "shift_id >= ? ", shift_id) if shift_id.present? }
  scope :to_shift_id, -> shift_id { where( "shift_id <= ? ", shift_id) if shift_id.present? }
  scope :by_status, -> status { where( :status => status) if status.present? }

  class << self
  include FundHelper
    def init_kiosk_transaction(member_id, amount, trans_type, shift_id, kiosk_id, ref_trans_id, casino_id)
      player = Player.find_by_member_id(member_id)
      player_id = player[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:transaction_type_id] = TransactionType.find_by_name(trans_type).id
      transaction[:shift_id] = shift_id
      transaction[:kiosk] = kiosk_id
      transaction[:status] = "validated"
      transaction[:casino_id] = casino_id
      transaction[:ref_trans_id] = ref_trans_id
      transaction[:trans_date] = Time.now
      transaction.save
      transaction
    end

    def save_deposit_transaction(member_id, amount, shift_id, kiosk_id, ref_trans_id, casino_id)
      init_player_transaction(member_id, amount, DEPOSIT, shift_id, kiosk_id, ref_trans_id, data)
    end

    def save_withdraw_transaction(member_id, amount, shift_id, kiosk_id, ref_trans_id, casino_id)
      init_player_transaction(member_id, amount, WITHDRAW, shift_id, kiosk_id, ref_trans_id, data)
    end

#TODO move to player model
    def get_player_by_card_member_id(type, id)
      if type == "member_id"
        Player.find_by_member_id(id)
      else
        Player.find_by_card_id(id)
      end
    end

    def only_deposit_withdraw
      by_transaction_type_id([TRANSACTION_TYPE_ID_LIST[:deposit], TRANSACTION_TYPE_ID_LIST[:withdraw]]).by_status(['completed', 'pending'])
    end

    def search_query_by_player(id_type, id_number, start_shift_id, end_shift_id)
      player_id = 0
      player = get_player_by_card_member_id(id_type, id_number)
      player_id = player.id unless player.nil?
      by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_deposit_withdraw
    end

    def search_query(*args)
      search_type = args[5].to_i
      if search_type == 0
        id_type = args[0]
        id_number = args[1]
        start_shift_id = args[2]
        end_shift_id = args[3]
        operation = args[6]
        search_query_by_player(id_type, id_number, start_shift_id, end_shift_id, operation)
      else
        slip_number = args[4].to_i

        search_query_by_slip_number(slip_number)
      end
    end
  end
end
