class KioskTransaction < ActiveRecord::Base
  attr_accessible :player_id, :shift_id, :transaction_type_id, :ref_trans_id, :amount, :status, :casino_id, :source_type, :kiosk_name, :trans_date, :created_at
  belongs_to :player
  belongs_to :shift
  belongs_to :transaction_type
  belongs_to :casino

  include FundHelper
  include ActionView::Helpers
  include TransactionQueries
  include TransactionAdapter

  DEPOSIT = 'deposit'
  WITHDRAW = 'withdraw'

  def pending!
    self.status = 'pending'
    self.save!
  end

  def completed!
    self.status = 'completed'
    self.save!
  end

  def rejected!
    self.status = 'rejected'
    self.save!
  end

  def display_status
    self.status
  end

  def cancelled?
    display_status == 'cancelled'
  end
  
  def validated?
    display_status == 'validated'
  end

  class << self
  include FundHelper
    def init_transaction(member_id, amount, trans_type, shift_id, kiosk_name, ref_trans_id, source_type, casino_id)
      player = Player.find_by_member_id(member_id)
      player_id = player[:id]
      transaction = new
      transaction[:player_id] = player_id
      transaction[:amount] = amount
      transaction[:transaction_type_id] = TransactionType.find_by_name(trans_type).id
      transaction[:shift_id] = shift_id
      transaction[:kiosk_name] = kiosk_name
      transaction[:status] = "validated"
      transaction[:source_type] = source_type
      transaction[:casino_id] = casino_id
      transaction[:ref_trans_id] = ref_trans_id
      transaction[:trans_date] = Time.now
      transaction.save
      transaction
    end

    def save_deposit_transaction(member_id, amount, shift_id, kiosk_name, ref_trans_id, source_type, casino_id)
      init_transaction(member_id, amount, DEPOSIT, shift_id, kiosk_name, ref_trans_id, source_type, casino_id)
    end

    def save_withdraw_transaction(member_id, amount, shift_id, kiosk_name, ref_trans_id, source_type, casino_id)
      init_transaction(member_id, amount, WITHDRAW, shift_id, kiosk_name, ref_trans_id, source_type, casino_id)
    end
  end
end
