class AddIndexToPurgeAt < ActiveRecord::Migration
  def up
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

  def down
    remove_index :accounting_dates, :purge_at
    remove_index :casinos, :purge_at
    remove_index :casinos_shift_types, :purge_at
    remove_index :currencies, :purge_at
    remove_index :kiosk_transactions, :purge_at
    remove_index :licensees, :purge_at
    remove_index :lock_types, :purge_at
    remove_index :player_transactions, :purge_at
    remove_index :players, :purge_at
    remove_index :players_lock_types, :purge_at
    remove_index :properties, :purge_at
    remove_index :shift_types, :purge_at
    remove_index :shifts, :purge_at
    remove_index :slip_types, :purge_at
    remove_index :transaction_types, :purge_at
    remove_index :transaction_types_slip_types, :purge_at
    remove_index :users, :purge_at
  end
end
