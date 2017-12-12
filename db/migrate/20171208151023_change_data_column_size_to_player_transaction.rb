class ChangeDataColumnSizeToPlayerTransaction < ActiveRecord::Migration
  def self.up
    change_column :player_transactions, :data, :string, :limit=>1024
  end

  def self.down
    change_column :player_transactions, :data, :string, :limit=>255
  end
end
