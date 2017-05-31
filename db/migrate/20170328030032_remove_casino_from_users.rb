class RemoveCasinoFromUsers < ActiveRecord::Migration
  def up
    execute "ALTER TABLE users DROP FOREIGN KEY fk_users_casino_id;"
    remove_column :users, :casino_id    
  end

  def down
    add_column :users, :casino_id, :int
    execute "ALTER TABLE users ADD CONSTRAINT fk_users_casino_id FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end
end
