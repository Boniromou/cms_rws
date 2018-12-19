class AddPaymentTypeAndSourceFunds < ActiveRecord::Migration
  def self.up
    add_column :player_transactions, :Payment_method_type, 'VARCHAR(45)', :null => true
    add_column :player_transactions, :Source_of_funds, 'VARCHAR(45)', :null => true
  end

  def self.down
    remove_column :player_transactions, :Payment_method_type
    remove_column :player_transactions, :Source_of_funds
  end
end
