class InsertLockTypesInitData < ActiveRecord::Migration
  def up
    execute "INSERT INTO lock_types(id,name, created_at, updated_at) values(1, 'cage_lock', '#{Time.now.utc}', '#{Time.now.utc}');"
    execute "INSERT INTO lock_types(id,name, created_at, updated_at) values(2, 'blacklist', '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM lock_types WHERE id > 0"
  end
end
