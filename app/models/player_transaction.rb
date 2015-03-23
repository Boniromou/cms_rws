class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :station, :status, :transaction_type_id, :user_id
end
