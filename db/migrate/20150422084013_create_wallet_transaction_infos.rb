class CreateWalletTransactionInfos < ActiveRecord::Migration
  def up
    create_table :wallet_transaction_infos do |t|
      t.integer :shift_id
      t.integer :user_id
      t.string :station
      t.integer :wallet_transaction_id

      t.timestamps
    end
    
    change_column :wallet_transaction_infos, :wallet_transaction_id, :bigint
    execute "ALTER TABLE wallet_transaction_infos ADD CONSTRAINT fk_shift_id FOREIGN KEY (shift_id) REFERENCES shifts(id);"
    execute "ALTER TABLE wallet_transaction_infos ADD CONSTRAINT fk_transaction_info_user_id FOREIGN KEY (user_id) REFERENCES users(id);"
    execute "ALTER TABLE wallet_transaction_infos ADD CONSTRAINT fk_info_wallet_id FOREIGN KEY (wallet_transaction_id) REFERENCES wallet_transactions(id);"
  end

  def down
    execute "ALTER TABLE wallet_transaction_infos DROP FOREIGN KEY fk_shift_id;"
    execute "ALTER TABLE wallet_transaction_infos DROP FOREIGN KEY fk_transaction_info_user_id;"
    execute "ALTER TABLE wallet_transaction_infos DROP FOREIGN KEY fk_info_wallet_id;"
    drop_table :wallet_transaction_infos
  end
end
