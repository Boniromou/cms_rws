class AddPropertyIdToTables < ActiveRecord::Migration
  def up
    add_column :players, :property_id, :integer, :null => false, :default => 20000
    execute "ALTER TABLE players ADD CONSTRAINT fk_players_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    
    add_column :player_transactions, :property_id, :integer, :null => false, :default => 20000
    execute "ALTER TABLE player_transactions ADD CONSTRAINT fk_player_transactions_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    
    add_column :users, :property_id, :integer, :null => false, :default => 20000
    execute "ALTER TABLE users ADD CONSTRAINT fk_users_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
    
    add_column :shifts, :property_id, :integer, :null => false, :default => 20000
    execute "ALTER TABLE shifts ADD CONSTRAINT fk_shifts_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
  end

  def down
    execute "ALTER TABLE shifts DROP FOREIGN KEY fk_shifts_property_id;"
    remove_column :shifts, :property_id

    execute "ALTER TABLE users DROP FOREIGN KEY fk_users_property_id;"
    remove_column :users, :property_id

    execute "ALTER TABLE player_transactions DROP FOREIGN KEY fk_player_transactions_property_id;"
    remove_column :player_transactions, :property_id

    execute "ALTER TABLE players DROP FOREIGN KEY fk_players_property_id;"
    remove_column :players, :property_id
  end
end
