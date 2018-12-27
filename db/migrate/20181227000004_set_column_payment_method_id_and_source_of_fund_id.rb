class SetColumnPaymentMethodIdAndSourceOfFundId < ActiveRecord::Migration
  def up
    execute "UPDATE player_transactions SET payment_method_id = 1 ;"
    execute "UPDATE player_transactions SET source_of_fund_id = 1 ;"
  end

  def down
    execute "UPDATE player_transactions SET payment_method_id = nil ;"
    execute "UPDATE player_transactions SET source_of_fund_id = nil ;"
  end
end

