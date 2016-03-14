class TransactionSlip < ActiveRecord::Base
  attr_accessible :casino_id, :slip_type_id, :next_number
  belongs_to :casino
  belongs_to :slip_type

  class << self
    def assign_slip_number(player_transaction)
      TransactionSlip.transaction do
        slip = TransactionSlip.lock.find_by_slip_type_id_and_casino_id(player_transaction.slip_type.id, player_transaction.casino_id)
        player_transaction.slip_number = slip.next_number
        player_transaction.save!
        
        slip.next_number = slip.next_number + 1
        slip.save!
      end
    end
  end
end
