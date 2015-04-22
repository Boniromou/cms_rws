class ChangePlayersColumn < ActiveRecord::Migration
  def up
    Player.delete_all
    rename_column :players, :player_name, :login_name
    rename_column :players, :status, :lock_state
    remove_column :players, :card_id
    remove_column :players, :member_id
    change_column :players, :balance, :bigint
    add_column :players, :shareholder, :string
    add_column :players, :played_at, :datetime
    add_column :players, :purge_at, :datetime
    add_column :players, :property_id, :int
    change_column_null :players, :property_id, false
    change_column_null :players, :currency_id, false
    execute "ALTER TABLE players ADD CONSTRAINT fk_property_id FOREIGN KEY (property_id) REFERENCES properties(id);"
  end

  def down
    execute "ALTER TABLE players DROP FOREIGN KEY fk_property_id;"
    rename_column :players, :login_name, :player_name
    rename_column :players, :lock_state, :status
    add_column :players, :card_id, :int
    add_column :players, :member_id, :int
    change_column :players, :balance, :int
    remove_column :players, :shareholder
    remove_column :players, :played_at
    remove_column :players, :purge_at
    remove_column :players, :property_id
    change_column_null :players, :currency_id, true
  end
end
