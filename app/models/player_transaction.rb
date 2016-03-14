class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :machine_token, :status, :transaction_type_id, :user_id, :slip_number, :created_at, :ref_trans_id, :data, :casino_id
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
  CREDIT_DEPOSIT = 'credit_deposit'
  CREDIT_EXPIRE = 'credit_expire'

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

  def credit_deposit_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == CREDIT_DEPOSIT
    result
  end

  def credit_expire_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == CREDIT_EXPIRE
    result
  end

  def credit_expire_duration_str
    result = ""
    result = self.data_hash[:duration] || "" if self.transaction_type.name == CREDIT_DEPOSIT
    result
  end

  def completed!
    PlayerTransaction.transaction do
      self.status = 'completed'
      self.save!
      self.update_slip_number! unless [CREDIT_DEPOSIT,CREDIT_EXPIRE].include?(self.transaction_type.name)
    end
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
    can_void_date = AccountingDate.current(self.casino_id).accounting_date - (ConfigHelper.new(self.casino_id).transaction_void_range).day
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
    self.transaction_type.transaction_types_slip_types.find_by_casino_id(self.casino_id).slip_type
  end

  def location
    if self.machine_token
      machine_token_array = self.machine_token.split('|') 
      return machine_token_array[2] + '/' + machine_token_array[4] if machine_token_array[2] && machine_token_array[4]
    end
    'N/A'
  end

  def update_slip_number!
    TransactionSlip.assign_slip_number(self)
  end

  def data_hash
    data_hash = YAML.load(self.data ||"---\n") || {}
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
    def init_player_transaction(member_id, amount, trans_type, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      player = Player.find_by_member_id(member_id)
      player_id = player[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:transaction_type_id] = TransactionType.find_by_name(trans_type).id
      transaction[:shift_id] = shift_id
      transaction[:machine_token] = machine_token
      transaction[:status] = "pending"
      transaction[:user_id] = user_id
      transaction[:casino_id] = user.casino_id
      transaction[:data] = data
      PlayerTransaction.transaction do
        transaction.save
        transaction[:trans_date] = transaction[:created_at]
        if ref_trans_id.nil?
          transaction[:ref_trans_id] = make_trans_id(transaction.id)
        else
          transaction[:ref_trans_id] = ref_trans_id
        end
        transaction.save
      end
      transaction
    end

    def save_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      init_player_transaction(member_id, amount, DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data)
    end

    def save_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      init_player_transaction(member_id, amount, WITHDRAW, shift_id, user_id, machine_token, ref_trans_id, data)
    end

    def save_void_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      init_player_transaction(member_id, amount, VOID_DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data)
    end

    def save_void_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      init_player_transaction(member_id, amount, VOID_WITHDRAW, shift_id, user_id, machine_token, ref_trans_id, data)
    end

    def save_credit_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      init_player_transaction(member_id, amount, CREDIT_DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data)
    end

    def save_credit_expire_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil)
      init_player_transaction(member_id, amount, CREDIT_EXPIRE, shift_id, user_id, machine_token, ref_trans_id, data)
    end

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

    def only_credit_deposit_expire
      by_transaction_type_id([TRANSACTION_TYPE_ID_LIST[:credit_deposit], TRANSACTION_TYPE_ID_LIST[:credit_expire]]).by_status(['completed', 'pending'])
    end

    def search_query_by_player(id_type, id_number, start_shift_id, end_shift_id, operation)      
      if id_number.empty?
        player_id = nil
      else
        player_id = 0
        player = get_player_by_card_member_id(id_type, id_number)
        player_id = player.id unless player.nil?
      end
      if operation == 'cash'
        by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_deposit_withdraw
      else
        by_player_id(player_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id).only_credit_deposit_expire
      end
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
        operation = args[6]
        search_query_by_player(id_type, id_number, start_shift_id, end_shift_id, operation)
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
