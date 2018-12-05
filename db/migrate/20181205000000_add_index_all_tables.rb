class AddIndexAllTables < ActiveRecord::Migration
  def change
      add_index :accounting_dates, :updated_at, :name => 'idx_updated_at'
      add_index :lock_types, :updated_at, :name => 'idx_updated_at'
      add_index :players, :updated_at, :name => 'idx_updated_at'
      add_index :shift_types, :updated_at, :name => 'idx_updated_at'
      add_index :player_transactions, :updated_at, :name => 'idx_updated_at'
      add_index :kiosk_transactions, :updated_at, :name => 'idx_updated_at'
      add_index :transaction_types, :updated_at, :name => 'idx_updated_at'
      add_index :users, :updated_at, :name => 'idx_updated_at'
      add_index :shifts, :updated_at, :name => 'idx_updated_at'
  end
end

