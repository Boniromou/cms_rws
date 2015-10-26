class TransactionSlip < ActiveRecord::Base
  attr_accessible :property_id, :slip_type_id, :next_number
  belongs_to :property
  belongs_to :slip_type

end
