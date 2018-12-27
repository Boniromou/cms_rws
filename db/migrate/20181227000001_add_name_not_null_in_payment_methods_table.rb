class AddNameNotNullInPaymentMethodsTable < ActiveRecord::Migration
  def up
    change_column_null :payment_methods, :name, false
  end

  def down
    change_column_null :payment_methods, :name, true
  end
end
