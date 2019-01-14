class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :machine_token, :status, :transaction_type_id, :user_id, :slip_number, :created_at, :ref_trans_id, :data, :casino_id
  belongs_to :player
  belongs_to :shift
  belongs_to :user
  belongs_to :transaction_type

  include FundHelper
  include ActionView::Helpers
  include TransactionQueries

  DEPOSIT = 'deposit'
  WITHDRAW = 'withdraw'
  VOID_DEPOSIT = 'void_deposit'
  VOID_WITHDRAW = 'void_withdraw'
  CREDIT_DEPOSIT = 'credit_deposit'
  CREDIT_EXPIRE = 'credit_expire'
  EXCEPTION_DEPOSIT = 'manual_deposit'
  EXCEPTION_WITHDRAW = 'manual_withdraw'
  VOID_EXCEPTION_DEPOSIT = 'void_manual_deposit'
  VOID_EXCEPTION_WITHDRAW = 'void_manual_withdraw'  
  def deposit_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == DEPOSIT || self.transaction_type.name == EXCEPTION_DEPOSIT
    result
  end

  def withdraw_amt_str
    result = ""
    result = to_display_amount_str(amount) if self.transaction_type.name == WITHDRAW|| self.transaction_type.name == EXCEPTION_WITHDRAW
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
    void_trans_type_name = "void_" + self.transaction_type.name.gsub('manual_','')
    void_trans_type = TransactionType.find_by_name(void_trans_type_name)
    trans_type_id = void_trans_type.id if void_trans_type
    PlayerTransaction.where(:ref_trans_id => self.ref_trans_id, :transaction_type_id => trans_type_id, :status => ['completed', 'pending']).first
  end

  def original_transaction
    trans_type_name = self.transaction_type.name.split('_').last
    trans_type_id = [TransactionType.find_by_name(trans_type_name).id,TransactionType.find_by_name(trans_type_name.prepend("manual_")).id]
    a = PlayerTransaction.where(:ref_trans_id => self.ref_trans_id, :transaction_type_id => trans_type_id, :status => ['completed']).first
    p a
    a
  end

  def slip_type
    self.transaction_type.transaction_types_slip_types.find_by_casino_id(self.casino_id).slip_type
  end

  def location
    if self.machine_token
      machine_token_array = self.machine_token.split('|') 
      return machine_token_array[2] + '/' + machine_token_array[4] if machine_token_array[2] && machine_token_array[4]
    end
    '---'
  end

  def update_slip_number!
    TransactionSlip.assign_slip_number(self)
  end

  def data_hash
    data_hash = YAML.load(self.data ||"---\n") || {}
  end

  def source_type
    'cage_transaction'
  end

  class << self
    include FundHelper
    def init_transaction(member_id, amount, trans_type, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, casino_id = nil, promotion_code = nil, executed_by = nil, payment_method_type, source_of_funds)
      transaction = new
      if casino_id.nil?
        transaction[:casino_id] = machine_token.nil? ? User.find_by_id(user_id).casino_id : Machine.parse_machine_token(machine_token)[:casino_id]
      else
        transaction[:casino_id] = casino_id
      end
      player = Player.find_by_member_id_and_licensee_id(member_id, Casino.find_by_id(transaction[:casino_id]).licensee_id)
      player_id = player[:id]
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:transaction_type_id] = TransactionType.find_by_name(trans_type).id
      transaction[:shift_id] = shift_id
      transaction[:machine_token] = machine_token
      transaction[:status] = "pending"
      transaction[:user_id] = user_id
      transaction[:promotion_code] = promotion_code
      transaction[:payment_method_id] = payment_method_type
      transaction[:source_of_fund_id] = source_of_funds
      data ||= {}
      data[:executed_by] = executed_by unless executed_by.nil?
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

    def save_internal_deposit_transaction(member_id, amount, shift_id, ref_trans_id, casino_id, promotion_code = nil, executed_by = nil, data = nil)
      init_transaction(member_id, amount, DEPOSIT, shift_id, '', nil, ref_trans_id, data, casino_id, promotion_code, executed_by)
    end

    def save_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type, source_of_funds)
      init_transaction(member_id, amount, DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, source_of_funds)
    end

    def save_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type, source_of_funds)
      init_transaction(member_id, amount, WITHDRAW, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, 1)
    end

    def save_void_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type, source_of_funds)
      init_transaction(member_id, amount, VOID_DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, source_of_funds)
    end

    def save_void_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type, source_of_funds)
      init_transaction(member_id, amount, VOID_WITHDRAW, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, 1)
    end

    def save_credit_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type = nil, source_of_funds = nil )
      init_transaction(member_id, amount, CREDIT_DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, source_of_funds)
    end

    def save_credit_expire_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type = nil, source_of_funds = nil)
      init_transaction(member_id, amount, CREDIT_EXPIRE, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, source_of_funds)
    end
    
    def save_exception_deposit_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type, source_of_funds)
      init_transaction(member_id, amount, EXCEPTION_DEPOSIT, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, source_of_funds)
    end   

    def save_exception_withdraw_transaction(member_id, amount, shift_id, user_id, machine_token, ref_trans_id = nil, data = nil, payment_method_type, source_of_funds)
      init_transaction(member_id, amount, EXCEPTION_WITHDRAW, shift_id, user_id, machine_token, ref_trans_id, data, payment_method_type, 1)
    end

    def search_query_by_slip_number(slip_number)
      by_slip_number(slip_number)
    end

    def search_transactions_by_user_and_shift(user_id, start_shift_id, end_shift_id)
      by_user_id(user_id).from_shift_id(start_shift_id).to_shift_id(end_shift_id)
    end 

    def search_transactions_by_shift_id(user_id, in_shift_id)
      by_user_id(user_id).in_shift_id(in_shift_id)
    end 
  end
end
