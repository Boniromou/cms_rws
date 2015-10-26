class InsertTransactionTypesData < ActiveRecord::Migration
  def up
    execute "INSERT INTO transaction_types(id, name, created_at, updated_at) values(3, 'void_deposit',  '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO transaction_types(id, name, created_at, updated_at) values(4, 'void_withdraw',  '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
  execute "DELETE FROM transaction_types WHERE id = 3;"
  execute "DELETE FROM transaction_types WHERE id = 4;"
  end
end
