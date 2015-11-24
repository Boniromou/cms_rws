class InsertCreditTransactionTypesData < ActiveRecord::Migration
  def up
    execute "INSERT INTO transaction_types(id, name, created_at, updated_at) values(5, 'credit_deposit',  '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO transaction_types(id, name, created_at, updated_at) values(6, 'credit_expire',  '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
  	execute "DELETE FROM transaction_types WHERE id = 5;"
  	execute "DELETE FROM transaction_types WHERE id = 6;"
  end
end
