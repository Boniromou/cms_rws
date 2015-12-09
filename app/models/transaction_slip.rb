class TransactionSlip < ActiveRecord::Base
  attr_accessible :property_id, :slip_type_id, :next_number
  belongs_to :property
  belongs_to :slip_type

  class << self
    def assign_slip_number(player_transaction)
      TransactionSlip.transaction do
        slip = TransactionSlip.lock.find_by_slip_type_id_and_property_id(player_transaction.slip_type.id, player_transaction.property_id)
        player_transaction.slip_number = slip.next_number
        slip.next_number = slip.next_number + 1
        slip.save!
        player_transaction.save!
      end
    end
  end
end
