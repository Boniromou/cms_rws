class DeletePlayerTransactions < ActiveRecord::Migration
  def up
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_shift_id;"
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_player_id;"
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_playerTransaction_user_id;"
    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_transaction_type_id;"
    drop_table :player_transactions
  end
  
  def down
    create_table :player_transactions do |t|
      t.integer :shift_id
      t.integer :player_id
      t.integer :user_id
      t.integer :transaction_type_id
      t.string :station
      t.string :status
      t.string :action
      t.integer :amount

      t.timestamps
    end

    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_shift_id FOREIGN KEY (shift_id) REFERENCES shifts(id);"
    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_playerTransaction_user_id FOREIGN KEY (user_id) REFERENCES users(id);"
    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_transaction_type_id FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(id);"
  end
end
