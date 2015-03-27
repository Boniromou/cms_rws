class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :station, :status, :transaction_type_id, :user_id

  def self.save_fund_in_transaction(member_id, amount)
    player_id = Player.find_by_member_id(member_id)[:id]
    transaction = new
    transaction[:player_id] = player_id
    transaction[:amount] = amount
    transaction.save
  end
end
