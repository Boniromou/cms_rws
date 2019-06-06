class AddIsMemberToPlayersAndAddPaymentMethodIdAndSourceOfFundIdToKiosk < ActiveRecord::Migration
  def up
    add_column :players, :is_member, :boolean, :default => true
    add_column :kiosk_transactions, :payment_method_id, :integer, :null => false
    add_column :kiosk_transactions, :source_of_fund_id, :integer, :null => false
  end

  def down
    remove_column :players, :is_member
    remove_column :kiosk_transactions, :payment_method_id
    remove_column :kiosk_transactions, :source_of_fund_id
  end
end

