class Player < ActiveRecord::Base
  attr_accessible :balance, :card_id, :currency_id,:member_id, :player_name, :status
end
