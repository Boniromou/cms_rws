class TransactionType < ActiveRecord::Base
  attr_accessible :name
  has_many :transaction_types_slip_types
end
