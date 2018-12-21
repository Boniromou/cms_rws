class ChangeTableNameOfPaymentMethodType < ActiveRecord::Migration
  def up
    rename_table :payment_method_type, :payment_method_types
  end

  def down
    rename_table :payment_method_types, :payment_method_type
  end
end
