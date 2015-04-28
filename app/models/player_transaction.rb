class PlayerTransaction < ActiveRecord::Base
  attr_accessible :action, :amount, :player_id, :shift_id, :station, :status, :transaction_type_id, :user_id

  DEPOSIT = 1;
  WITHDRAWAL = 2;
  
  def deposit_amt_str
    result = ""
    result = amount.to_s if transaction_type_id == DEPOSIT
    result
  end

  def withdrawal_amt_str
    result = ""
    result = amount.to_s if transaction_type_id == WITHDRAWAL
    result
  end
    

  def self.save_fund_in_transaction(member_id, amount, shift_id, user_id, station)
    player_id = Player.find_by_member_id(member_id)[:id]
    transaction = new
    transaction[:player_id] = player_id
    transaction[:amount] = amount
    transaction[:shift_id] = shift_id
    transaction[:station] = station
    transaction[:status] = "complete"
    transaction[:transaction_type_id] = TransactionType.find_by_name("Deposit").id;
    transaction[:user_id] = user_id
    transaction.save
    transaction
  end

  def self.save_fund_out_transaction(member_id, amount, shift_id, user_id, station)
    player_id = Player.find_by_member_id(member_id)[:id]
    transaction = new
    transaction[:player_id] = player_id
    transaction[:amount] = amount
    transaction[:shift_id] = shift_id
    transaction[:station] = station
    transaction[:status] = "complete"
    transaction[:transaction_type_id] = TransactionType.find_by_name("Withdrawal").id;
    transaction[:user_id] = user_id
    transaction.save
    transaction
  end
  
  scope :since, -> start_time { where("created_at >= ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("created_at <= ?", end_time) if end_time.present? }
  scope :by_player_id, -> player_id { where("player_id = ?", player_id) if player_id.present? }
  scope :by_transaction_id, -> transaction_id { where("id = ?", transaction_id) if transaction_id.present? }

  def self.search_query(*args)
    id_type = args[0]
    id_number = args[1]
    start_time = args[2]
    end_time = args[3]
    transaction_id = args[4]
    
    if id_type == "member_id"
      player = Player.find_by_member_id(id_number)
    else
      player = Player.find_by_card_id(id_number)
    end
    player_id = 0 if id_number!=""
    player_id = player.id unless player.nil?
    by_transaction_id(transaction_id).by_player_id(player_id).since(start_time).until(end_time)
  end
end
