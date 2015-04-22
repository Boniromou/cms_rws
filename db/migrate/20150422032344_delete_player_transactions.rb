class DeletePlayerTransactions < ActiveRecord::Migration
  def up
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_shift_id;"
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_player_id;"
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_playerTransaction_user_id;"
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_transaction_type_id;"
    drop_table :player_transactions
  end
  
  def down
  end
end
