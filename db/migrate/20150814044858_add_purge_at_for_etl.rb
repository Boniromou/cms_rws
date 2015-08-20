class AddPurgeAtForEtl < ActiveRecord::Migration
  def up
  	add_column :player_transactions, :purge_at, :datetime
  	add_column :transaction_types, :purge_at, :datetime
  	add_column :accounting_dates, :purge_at, :datetime
  	add_column :stations, :purge_at, :datetime
  	add_column :locations, :purge_at, :datetime
  	add_column :players, :purge_at, :datetime
  	add_column :shifts, :purge_at, :datetime
  	add_column :shift_types, :purge_at, :datetime
  	add_column :users, :purge_at, :datetime
  end

  def down
  	remove_column :player_transactions, :purge_at
  	remove_column :transaction_types, :purge_at
  	remove_column :accounting_dates, :purge_at
  	remove_column :stations, :purge_at
  	remove_column :locations, :purge_at
  	remove_column :players, :purge_at
  	remove_column :shifts, :purge_at
  	remove_column :shift_types, :purge_at
  	remove_column :users, :purge_at
  end
end
