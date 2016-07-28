class CreateKioskTransactions < ActiveRecord::Migration
  def up
    create_table :kiosk_transactions do |t|
      t.integer :shift_id, :null => false
      t.integer :player_id, :null => false
      t.integer :transaction_type_id, :null => false
      t.string :ref_trans_id, :limit => 45
      t.column :amount, 'BIGINT'
      t.string :status, :limit => 45
      t.datetime :trans_date
      t.integer :casino_id, :null => false
      t.string :kiosk_id, :limit => 45
      t.string :source_type, :limit => 45

      t.timestamps
    end
    execute "ALTER TABLE kiosk_transactions ADD CONSTRAINT fk_kiosk_shift_id FOREIGN KEY (shift_id) REFERENCES shifts(id);"
    execute "ALTER TABLE kiosk_transactions ADD CONSTRAINT fk_kiosk_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
    execute "ALTER TABLE kiosk_transactions ADD CONSTRAINT fk_kiosk_transaction_type_id FOREIGN KEY (transaction_type_id) REFERENCES transaction_types(id);"
    execute "ALTER TABLE kiosk_transactions ADD CONSTRAINT fk_kiosk_casino_id FOREIGN KEY (casino_id) REFERENCES casinos(id);"
    
    change_column :kiosk_transactions, :id, "BIGINT UNSIGNED NOT NULL AUTO_INCREMENT"
  end

  def down
    execute "ALTER TABLE kiosk_transactions DROP FOREIGN KEY fk_kiosk_shift_id;"
    execute "ALTER TABLE kiosk_transactions DROP FOREIGN KEY fk_kiosk_player_id;"
    execute "ALTER TABLE kiosk_transactions DROP FOREIGN KEY fk_kiosk_casino_id;"
    execute "ALTER TABLE kiosk_transactions DROP FOREIGN KEY fk_kiosk_transaction_type_id;"
    drop_table :kiosk_transactions
  end
end
