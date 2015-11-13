class AddMachineTokenToPlayerTransactions < ActiveRecord::Migration
  def up
    remove_column :player_transactions, :station_id
    add_column :player_transactions, :machine_token, :string
  end

  def down
    add_column :player_transactions, :station_id, :int
    remove_column :player_transactions, :machine_token
  end
end
