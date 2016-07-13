class ChangeRefTransIdLength < ActiveRecord::Migration
  def up
    change_column :player_transactions, :ref_trans_id , :string, :limit => 45
  end

  def down
    change_column :player_transactions, :ref_trans_id , :string, :limit => 255
  end
end
