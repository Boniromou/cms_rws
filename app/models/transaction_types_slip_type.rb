class TransactionTypesSlipType < ActiveRecord::Base
  attr_accessible :casino_id, :transaction_type_id, :slip_type_id
  belongs_to :casino
  belongs_to :transaction_type
  belongs_to :slip_type
end
