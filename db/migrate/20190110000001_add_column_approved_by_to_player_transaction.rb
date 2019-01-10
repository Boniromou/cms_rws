class AddColumnApprovedByToPlayerTransaction < ActiveRecord::Migration
  def up
    add_column :player_transactions, :approved_by, :string
  end
  def down
    drop_column :player_transactions, :approved_by
  end
end
