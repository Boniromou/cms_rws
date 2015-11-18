class AddSlipNumberColumnToPlayerTransactions < ActiveRecord::Migration
  def change
    add_column :player_transactions, :slip_number, :int
  end
end
