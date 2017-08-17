class AddColumnPromotionCodeWithIndex < ActiveRecord::Migration
  def self.up
      add_column :player_transactions, :promotion_code, 'VARCHAR(45)', :null => true
      add_index :player_transactions, :promotion_code, :name => 'promotion_code', :unique => false
  end

  def self.down
      remove_column :player_transactions, :promotion_code
  end
end

