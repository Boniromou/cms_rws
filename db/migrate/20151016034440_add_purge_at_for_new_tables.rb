class AddPurgeAtForNewTables < ActiveRecord::Migration
  def up
  	add_column :properties, :purge_at, :datetime
  	add_column :properties_shift_types, :purge_at, :datetime
  	add_column :players_lock_types, :purge_at, :datetime
  	add_column :lock_types, :purge_at, :datetime
  	add_column :currencies, :purge_at, :datetime
  end

  def down
  	remove_column :properties, :purge_at
  	remove_column :properties_shift_types, :purge_at
  	remove_column :players_lock_types, :purge_at
  	remove_column :lock_types, :purge_at
  	remove_column :currencies, :purge_at
  end
end
