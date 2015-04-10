class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :station, :status, :transaction_type_id, :user_id

  def self.save_fund_in_transaction(member_id, amount, shift_id, user_id, station)
    player_id = Player.find_by_member_id(member_id)[:id]
    transaction = new
    transaction[:player_id] = player_id
    transaction[:action] = "deposit"
    transaction[:amount] = amount
 #   transaction[:shift_id] = shift_id
    transaction[:station] = station
    transaction[:status] = "complete"
    transaction[:transaction_type_id] = TransactionType.find_by_name("Deposit").id;
    transaction[:user_id] = user_id
    transaction.save
  end

  def self.save_fund_out_transaction(member_id, amount, shift_id, user_id, station)
    player_id = Player.find_by_member_id(member_id)[:id]
    transaction = new
    transaction[:player_id] = player_id
    transaction[:action] = "withdraw"
    transaction[:amount] = amount
 #   transaction[:shift_id] = shift_id
    transaction[:station] = station
    transaction[:status] = "complete"
    transaction[:transaction_type_id] = TransactionType.find_by_name("Withdrawal").id;
    transaction[:user_id] = user_id
    transaction.save
  end
end
