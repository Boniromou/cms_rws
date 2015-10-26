class InsertSlipTypesInitData < ActiveRecord::Migration
  def up
    execute "INSERT INTO slip_types(id,name, created_at, updated_at) values(1, 'deposit', '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO slip_types(id,name, created_at, updated_at) values(2, 'withdraw', '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM slip_types WHERE id > 0"
  end
end
