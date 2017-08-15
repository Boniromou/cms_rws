class ChangeCasinoIdToNullableFromUsers < ActiveRecord::Migration
  def up
    execute "ALTER TABLE users DROP FOREIGN KEY fk_users_casino_id;"
    change_column :users, :casino_id, :int, null: true
  end

  def down
    change_column :users, :casino_id, :int, null: false
    execute "ALTER TABLE users ADD CONSTRAINT fk_users_casino_id FOREIGN KEY (casino_id) REFERENCES casinos(id);"
  end
end
