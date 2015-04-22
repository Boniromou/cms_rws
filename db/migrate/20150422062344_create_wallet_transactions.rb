class CreateWalletTransactions < ActiveRecord::Migration
  def up
    create_table :wallet_transactions do |t|
      t.string :ref_trans_id, null: false
      t.integer :amt
      t.integer :before_balance
      t.integer :after_balance
      t.string :aasm_state
      t.string :trans_type, null: false
      t.datetime :trans_date
      t.integer :property_id, null: false
      t.integer :player_id, null: false
      t.datetime :purge_at

      t.timestamps
    end
    change_column :wallet_transactions, :id, :bigint
    change_column :wallet_transactions, :amt, :bigint
    change_column :wallet_transactions, :before_balance, :bigint
    change_column :wallet_transactions, :after_balance, :bigint

    execute "ALTER TABLE wallet_transactions ADD CONSTRAINT fk_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
    execute "ALTER TABLE wallet_transactions MODIFY COLUMN `id` BIGINT(20) NOT NULL AUTO_INCREMENT;"
  end

  def down
    execute "ALTER TABLE wallet_transactions DROP FOREIGN KEY fk_player_id;"
    drop_table :wallet_transactions
  end
end
