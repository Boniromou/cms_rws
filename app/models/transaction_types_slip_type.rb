class TransactionTypesSlipType < ActiveRecord::Base
  attr_accessible :property_id, :transaction_type_id, :slip_type_id
  belongs_to :property
  belongs_to :transaction_type
  belongs_to :slip_type
end
