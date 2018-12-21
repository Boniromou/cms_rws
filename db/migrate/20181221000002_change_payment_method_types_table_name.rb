class ChangePaymentMethodTypesTableName < ActiveRecord::Migration
  def up
    rename_table :payment_method_types, :payment_methods
  end

  def down
    rename_table :payment_methods, :payment_method_types
  end
end

