class AddIndexToPurgeAt < ActiveRecord::Migration
  def change
    add_index :accounting_dates, :purge_at
    add_index :casinos, :purge_at
    add_index :casinos_shift_types, :purge_at
    add_index :currencies, :purge_at
    add_index :kiosk_transactions, :purge_at
    add_index :licensees, :purge_at
    add_index :lock_types, :purge_at
    add_index :player_transactions, :purge_at
    add_index :players, :purge_at
    add_index :players_lock_types, :purge_at
    add_index :properties, :purge_at
    add_index :shift_types, :purge_at
    add_index :shifts, :purge_at
    add_index :slip_types, :purge_at
    add_index :transaction_types, :purge_at
    add_index :transaction_types_slip_types, :purge_at
    add_index :users, :purge_at
  end
end
