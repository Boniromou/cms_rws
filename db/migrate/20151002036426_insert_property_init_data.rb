class InsertPropertyInitData < ActiveRecord::Migration
  def up
    execute "INSERT INTO properties(id,name, secret_key, created_at, updated_at) values(20000, 'MockUp', 'test_key', '#{Time.now.utc}', '#{Time.now.utc}');"
  end

  def down
    execute "DELETE FROM properties WHERE id = 20000"
  end
end
