class TransactionSlip < ActiveRecord::Base
  attr_accessible :property_id, :slip_type_id, :next_number
  belongs_to :property
  belongs_to :slip_type

  def provide_next_number!
    next_number = self.next_number
    self.next_number = self.next_number + 1
    self.save!
    next_number
  end

end
