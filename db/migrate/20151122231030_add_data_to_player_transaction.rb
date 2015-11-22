class AddDataToPlayerTransaction < ActiveRecord::Migration
  def up
    add_column :player_transactions, :data, :string
  end

  def down
    remove_column :player_transactions, :data
  end
end
