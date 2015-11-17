class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :machine_token, :status, :transaction_type_id, :user_id, :slip_number, :created_at
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

  TRANSACTION_TYPE_ID_LIST = {:deposit => 1, :withdraw => 2, :void_deposit => 3, :void_withdraw => 4}

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
    self.update_slip_number!
  end

  def rejected!
    self.status = 'rejected'
    self.save!
  end

  def display_status
    return 'voided' if self.void_transaction && self.void_transaction.status == 'completed'
    return 'voiding' if self.void_transaction && self.void_transaction.status == 'pending'
    self.status
  end

  def voided?
    display_status == 'voided'
  end

  def can_void?
    #TODO set by configuration, how many days can void
    can_void_date = AccountingDate.current.accounting_date - 1.day
    void_transaction.nil? && self.shift.accounting_date >= can_void_date
  end

  def void_transaction
    void_trans_type_name = "void_" + self.transaction_type.name
    void_trans_type = TransactionType.find_by_name(void_trans_type_name)
    trans_type_id = void_trans_type.id if void_trans_type
    PlayerTransaction.where(:ref_trans_id => self.ref_trans_id, :transaction_type_id => trans_type_id, :status => ['completed', 'pending']).first
  end

  def original_transaction
    trans_type_name = self.transaction_type.name.split('_')[1]
    trans_type = TransactionType.find_by_name(trans_type_name)
    trans_type_id = trans_type.id if trans_type
    PlayerTransaction.where(:ref_trans_id => self.ref_trans_id, :transaction_type_id => trans_type_id, :status => ['completed']).first
  end

  def slip_type
    self.transaction_type.transaction_types_slip_types.find_by_property_id(self.property_id).slip_type
  end

  def location
    machine_token_array = self.machine_token.split('|') if self.machine_token
    return machine_token_array[2] + '/' + machine_token_array[4] if machine_token_array[2] && machine_token_array[4]
    'N/A'
  end

  def update_slip_number!
    PlayerTransaction.transaction do
      transaction_slip = self.slip_type.transaction_slips.lock.find_by_property_id(self.property_id)
      self.slip_number = transaction_slip.provide_next_number!
      self.save!
    end
  end

  scope :since, -> start_time { where("created_at >= ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("created_at <= ?", end_time) if end_time.present? }
  scope :by_player_id, -> player_id { where("player_id = ?", player_id) if player_id.present? }
  scope :by_transaction_id, -> transaction_id { where("id = ?", transaction_id) if transaction_id.present? }
  scope :by_shift_id, -> shift_id { where( "shift_id = ? ", shift_id) if shift_id.present? }
  scope :by_user_id, -> user_id { where( "user_id = ?", user_id) if user_id.present? }
  scope :by_transaction_type_id, -> trans_types { where(:transaction_type_id => trans_types) if trans_types.present?}
  scope :from_shift_id, -> shift_id { where( "shift_id >= ? ", shift_id) if shift_id.present? }
  scope :to_shift_id, -> shift_id { where( "shift_id <= ? ", shift_id) if shift_id.present? }
  scope :by_slip_number, -> slip_number { where("slip_number = ?", slip_number) if slip_number.present? }
  scope :by_status, -> status { where( :status => status) if status.present? }

  class << self
  include FundHelper
    def init_player_transaction(member_id, amount, trans_type, shift_id, user_id, machine_token, ref_trans_id = nil)
      player = Player.find_by_member_id(member_id)
      player_id = player[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:transaction_type_id] = TransactionType.find_by_name(trans_type).id;
      transaction[:shift_id] = shift_id
      transaction[:machine_token] = machine_token
      transaction[:status] = "pending"
      transaction[:user_id] = user_id
      transaction[:trans_date] = Time.now
      transaction[:property_id] = player[:property_id]
      transaction.save
      if ref_trans_id.nil?
        transaction[:ref_trans_id] = make_trans_id(transaction.id)
      else
        transaction[:ref_trans_id] = ref_trans_id
      end
        transaction.save
      transaction
    end

    def save_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil)
      init_player_transaction(member_id, amount, DEPOSIT, shift_id, user_id, machine_token, ref_trans_id)
    end

    def save_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil)
      init_player_transaction(member_id, amount, WITHDRAW, shift_id, user_id, machine_token, ref_trans_id)
    end

    def save_void_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil)
      init_player_transaction(member_id, amount, VOID_DEPOSIT, shift_id, user_id, machine_token, ref_trans_id)
    end

    def save_void_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil)
      init_player_transaction(member_id, amount, VOID_WITHDRAW, shift_id, user_id, machine_token, ref_trans_id)
    end

    def get_player_by_card_member_id(type, id)
      if type == "member_id"
        Player.find_by_member_id(id)
      else
        Player.find_by_card_id(id)
      end
    end

    def only_deposit_withdraw
      by_transaction_type_id([TRANSACTION_TYPE_ID_LIST[:deposit],TRANSACTION_TYPE_ID_LIST[:withdraw]]).by_status(['completed','pending'])
    end

    def search_query_by_player(id_type, id_number, start_shift_id, end_shift_id)      
      if id_number.empty?
        player_id = nil
      else
        player_id = 0
        player = get_player_by_card_member_id(id_type, id_number)
        player_id = player.id unless player.nil?
      end

      by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_deposit_withdraw
    end

    def search_query_by_slip_number(slip_number)
      by_slip_number(slip_number).only_deposit_withdraw
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
        slip_number = args[4].to_i

        search_query_by_slip_number(slip_number)
      end
    end

    def search_transactions_by_user_and_shift(user_id, start_shift_id, end_shift_id)
      by_user_id(user_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_deposit_withdraw
    end
  end
end
