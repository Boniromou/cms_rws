class ChangePaymentMethodTypeColumnName < ActiveRecord::Migration
  def up
    rename_column :player_transactions, :payment_method_type_id, :payment_method_id
  end

  def down
    rename_column :player_transactions, :payment_method_id, :payment_method_type_id
  end
end
