class ChangeColumnInPlayerTransactions < ActiveRecord::Migration
  def up
    rename_column :player_transactions, :Payment_method_type, :payment_method_type_id
    rename_column :player_transactions, :Source_of_funds, :source_of_fund_id
  end

  def down
    rename_column :player_transactions, :payment_method_type_id, :Payment_method_type
    rename_column :player_transactions, :source_of_fund_id, :Source_of_funds
  end
end
