class CreatePlayersLockTypes < ActiveRecord::Migration
  def up
    create_table :players_lock_types do |t|
      t.integer :player_id, :null => false
      t.integer :lock_type_id, :null => false
      t.string :status, :null => false, :limit => 45

      t.timestamps
    end
    execute "ALTER TABLE players_lock_types ADD CONSTRAINT fk_players_lock_types_player_id FOREIGN KEY (player_id) REFERENCES players(id);"
    execute "ALTER TABLE players_lock_types ADD CONSTRAINT fk_players_lock_types_lock_type_id FOREIGN KEY (lock_type_id) REFERENCES lock_types(id);"
    add_index :players_lock_types, [:player_id, :lock_type_id], :name => 'players_lock_types_player_id_lock_type_id', :unique => true
  end

  def down
    drop_table :players_lock_types
  end
end
