class ChangePlayerTransactionsIdToUnsigned < ActiveRecord::Migration
  def up
     change_column :player_transactions, :id,"BIGINT UNSIGNED NOT NULL AUTO_INCREMENT"
  end

  def down
     change_column :player_transactions, :id,"BIGINT NOT NULL AUTO_INCREMENT"
  end
end
