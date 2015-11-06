class InsertTransactionSlipsInitData < ActiveRecord::Migration
  def up
    execute "INSERT INTO transaction_slips(property_id, slip_type_id, next_number, created_at, updated_at) values(20000, 1, 10001, '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO transaction_slips(property_id, slip_type_id, next_number, created_at, updated_at) values(20000, 2, 10001, '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM transaction_slips WHERE property_id = 20000"
  end
end
