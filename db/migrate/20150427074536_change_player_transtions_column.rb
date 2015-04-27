class ChangePlayerTranstionsColumn < ActiveRecord::Migration
  def up
    PlayerTransaction.delete_all
    remove_column :player_transactions, :station
    remove_column :player_transactions, :action
    add_column :player_transactions, :station_id, :int
    add_column :player_transactions, :ref_trans_id, :string
    change_column :player_transactions, :amount, :bigint
  end

  def down
    change_column :player_transactions, :amount, :int
    remove_column :player_transactions, :ref_trans_id
    remove_column :player_transactions, :station_id
    add_column :player_transactions, :action, :string
    add_column :player_transactions, :station, :string
  end
end
