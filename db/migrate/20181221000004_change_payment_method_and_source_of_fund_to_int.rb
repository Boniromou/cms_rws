class ChangePaymentMethodAndSourceOfFundToInt < ActiveRecord::Migration
  def up
    change_column :player_transactions, :payment_method_id , :integer
    
    change_column :player_transactions, :source_of_fund_id , :integer
  end

  def down
    change_column :player_transactions, :payment_method_id , :string
    change_column :player_transactions, :payment_method_id , :string
  end
end

