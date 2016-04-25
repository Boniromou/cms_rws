class ChangePlayerTransactionsIdToBigInt < ActiveRecord::Migration
  def up
    change_column :player_transactions, :id, :bigint
  end

  def down
    change_column :player_transactions, :id, :bigint
  end
end
