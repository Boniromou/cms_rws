class ChangePaymentMethodIdSourceOfFundIdNotNull < ActiveRecord::Migration
  def up
    change_column :player_transactions, :payment_method_id, :integer, :default => 1, :null => false
    change_column :player_transactions, :source_of_fund_id, :integer, :default => 1, :null => false
  end

  def down
    change_column_null :player_transactions, :payment_method_id, true
    change_column_null :source_of_fund_id, :source_of_fund_id, true
  end
end
