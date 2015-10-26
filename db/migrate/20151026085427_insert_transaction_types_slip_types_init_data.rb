class InsertTransactionTypesSlipTypesInitData < ActiveRecord::Migration
  def up
    execute "INSERT INTO transaction_types_slip_types(property_id, transaction_type_id, slip_type_id, created_at, updated_at) values(20000, 1, 1, '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO transaction_types_slip_types(property_id, transaction_type_id, slip_type_id, created_at, updated_at) values(20000, 2, 2, '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO transaction_types_slip_types(property_id, transaction_type_id, slip_type_id, created_at, updated_at) values(20000, 3, 1, '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO transaction_types_slip_types(property_id, transaction_type_id, slip_type_id, created_at, updated_at) values(20000, 4, 2, '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM transaction_types_slip_types WHERE property_id = 20000"
  end
end
