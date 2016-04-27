class ChangePlayerTransactionsIdToBigInt < ActiveRecord::Migration
  def up
    change_column :player_transactions, :id, "BIGINT NOT NULL AUTO_INCREMENT"
  end

  def down
    change_column :player_transactions, :id, "INTEGER NOT NULL AUTO_INCREMENT"
  end
end
