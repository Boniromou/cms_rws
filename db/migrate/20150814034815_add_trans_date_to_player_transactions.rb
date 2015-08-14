class AddTransDateToPlayerTransactions < ActiveRecord::Migration
  def up
  	add_column :player_transactions, :trans_date, :datetime
  end

  def down
  	remove_column :player_transactions, :trans_date
  end
end
