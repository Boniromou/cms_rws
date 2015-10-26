class InsertLockTypesData < ActiveRecord::Migration
  def up
    execute "INSERT INTO lock_types(id,name, created_at, updated_at) values(3, 'pending', '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM lock_types WHERE id = 3"
  end
end
