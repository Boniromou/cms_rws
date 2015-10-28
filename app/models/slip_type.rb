class SlipType < ActiveRecord::Base
  attr_accessible :name
  has_many :transaction_slips
end
